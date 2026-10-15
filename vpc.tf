# Fully private VPC: no internet gateway and no NAT gateway. Everything the
# instance needs (SSM, ECR, CloudWatch Logs, KMS, S3) arrives over VPC endpoints.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr
  azs  = local.azs

  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  map_public_ip_on_launch = false

  create_database_subnet_group       = true
  create_database_subnet_route_table = true

  # Required so that interface endpoints can use private DNS names.
  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = false

  # Default security group is locked shut with no ingress and no egress.
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  # VPC flow logs to a KMS-encrypted CloudWatch log group.
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_destination_type                       = "cloud-watch-logs"
  flow_log_cloudwatch_log_group_kms_key_id        = aws_kms_key.stack.arn
  flow_log_cloudwatch_log_group_retention_in_days = var.log_retention_in_days
  flow_log_traffic_type                           = "ALL"
}
