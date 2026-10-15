data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = var.name_prefix

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Non-overlapping /24s carved out of the VPC CIDR, one set per tier per AZ.
  # There are no public subnets: the VPC has no internet gateway.
  private_subnets  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i)]
  database_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 20)]
}
