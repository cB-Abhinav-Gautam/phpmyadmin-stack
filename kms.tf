# Single customer-managed key for the whole stack: EBS root volume, RDS storage,
# Performance Insights, the RDS-managed master password secret, ECR images and
# CloudWatch log groups.
resource "aws_kms_key" "stack" {
  description             = "Customer-managed key for the ${local.name} stack (EBS, RDS, Secrets Manager, ECR, CloudWatch Logs)."
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_deletion_window_in_days
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name}-stack-key"
    Statement = [
      {
        Sid    = "EnableAccountAdministration"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      },
      {
        Sid    = "AllowStackServices"
        Effect = "Allow"
        Principal = {
          Service = [
            "rds.amazonaws.com",
            "monitoring.rds.amazonaws.com",
            "secretsmanager.amazonaws.com",
            "ecr.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "stack" {
  name          = "alias/${local.name}-stack"
  target_key_id = aws_kms_key.stack.key_id
}
