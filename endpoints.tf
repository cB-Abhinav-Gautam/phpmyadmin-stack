locals {
  # Interface endpoints that replace internet egress for the instance.
  #   ssm / ssmmessages / ec2messages -> Session Manager port forwarding
  #   ecr.api / ecr.dkr               -> pulling the phpMyAdmin image
  #   logs                            -> CloudWatch Logs
  #   kms                             -> decrypting the ECR image key and DB secret
  interface_endpoints = [
    "ssm",
    "ssmmessages",
    "ec2messages",
    "ecr.api",
    "ecr.dkr",
    "logs",
    "kms",
    "secretsmanager"
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  tags = {
    Name = "${local.name}-${replace(each.value, ".", "-")}"
  }
}

# Gateway endpoint: ECR stores image layers in S3, so this is required for pulls.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = {
    Name = "${local.name}-s3"
  }
}
