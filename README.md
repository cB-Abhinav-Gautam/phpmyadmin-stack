# phpmyadmin-stack

phpMyAdmin on AWS, backed by RDS MySQL, with **no internet exposure at all**.

## Architecture

| Layer | Resource |
|---|---|
| Network | `terraform-aws-modules/vpc` 5.16.0 — private + database subnets only. **No internet gateway, no NAT gateway.** VPC flow logs to a KMS-encrypted CloudWatch log group (365 days). |
| Private AWS access | Interface endpoints for SSM, SSM Messages, EC2 Messages, ECR API, ECR DKR, CloudWatch Logs, KMS and Secrets Manager, plus an S3 gateway endpoint for ECR image layers. |
| Key | One customer-managed KMS key for the whole stack: EBS, RDS, Performance Insights, the DB secret, ECR and CloudWatch Logs. Rotation enabled, explicit key policy. |
| Database | `aws_db_instance` MySQL 8 — encrypted, Multi-AZ, private, 7-day backups, deletion protection, IAM auth, enhanced monitoring, Performance Insights, log exports. |
| Image registry | Private ECR repository, immutable tags, scan-on-push, KMS-encrypted. |
| App | One EC2 instance (Amazon Linux 2023) in a private subnet running the phpMyAdmin container bound to `127.0.0.1`. IMDSv2 required, encrypted root volume, detailed monitoring, EBS-optimised, no public IP. |

## How access works

There is **no load balancer and no inbound security group rule**. phpMyAdmin
listens on `127.0.0.1:8080` on the instance. You reach it by opening an SSM
port-forwarding session, which rides the SSM agent's outbound connection and is
TLS-encrypted by Session Manager:

```sh
aws ssm start-session \
  --target "$(tofu output -raw instance_id)" \
  --region us-east-2 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["8080"],"localPortNumber":["8080"]}'
```

Then browse to <http://localhost:8080>.

`tofu output -raw port_forward_command` prints this command pre-filled.

## Before the first apply: mirror the image

The VPC has no internet egress, so the instance cannot pull from Docker Hub. The
phpMyAdmin image must exist in the stack's ECR repository first:

```sh
REPO="$(tofu output -raw ecr_repository_url)"
aws ecr get-login-password --region us-east-2 \
  | docker login --username AWS --password-stdin "${REPO%%/*}"

docker pull phpmyadmin:5.2-apache
docker tag  phpmyadmin:5.2-apache "$REPO:5.2-apache"
docker push "$REPO:5.2-apache"
```

Tags are immutable, so pushing a given tag twice will be rejected — bump
`phpmyadmin_image_tag` to roll forward.

## Logging in

RDS generates the master password and stores it in Secrets Manager under the
stack KMS key. It is never written to Terraform state or to instance user data.

```sh
aws secretsmanager get-secret-value \
  --secret-id "$(tofu output -raw db_master_secret_arn)" \
  --query SecretString --output text
```

Use that username and password at the phpMyAdmin login screen.

## Required IAM permissions

This stack creates three IAM roles (instance role, RDS enhanced monitoring role,
VPC flow logs role). The deploying principal therefore needs `iam:CreateRole`,
`iam:AttachRolePolicy`, `iam:PutRolePolicy` and `iam:CreateInstanceProfile`, plus
KMS permissions (`kms:CreateKey`, `kms:CreateGrant`, `kms:PutKeyPolicy`).
`tofu plan` succeeds without them; `tofu apply` does not.
