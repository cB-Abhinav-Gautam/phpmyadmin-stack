# ---------------------------------------------------------------------------
# VPC interface endpoints
# ---------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name}-vpc-endpoints"
  description = "Allows HTTPS from the phpMyAdmin instance to the AWS interface endpoints."
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoints_https" {
  security_group_id            = aws_security_group.vpc_endpoints.id
  description                  = "HTTPS from the phpMyAdmin instance to AWS interface endpoints."
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

# ---------------------------------------------------------------------------
# phpMyAdmin application instance
#
# No ingress rules at all. phpMyAdmin binds to 127.0.0.1 on the instance and is
# reached through an SSM port-forwarding session, which rides the SSM agent's
# outbound connection. Egress is confined to the VPC: AWS endpoints and the DB.
# ---------------------------------------------------------------------------
resource "aws_security_group" "app" {
  name        = "${local.name}-app"
  description = "phpMyAdmin instance. No ingress; reached only via SSM port forwarding."
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "app_to_endpoints" {
  security_group_id            = aws_security_group.app.id
  description                  = "HTTPS to AWS interface endpoints (SSM, ECR, Logs, KMS, Secrets Manager)."
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_s3_prefix_list" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS to S3 via the gateway endpoint, for ECR image layers."
  prefix_list_id    = aws_vpc_endpoint.s3.prefix_list_id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_dns_udp" {
  security_group_id = aws_security_group.app.id
  description       = "DNS over UDP to the VPC resolver, to resolve endpoint private DNS names."
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

resource "aws_vpc_security_group_egress_rule" "app_dns_tcp" {
  security_group_id = aws_security_group.app.id
  description       = "DNS over TCP to the VPC resolver, to resolve endpoint private DNS names."
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "MySQL egress from the phpMyAdmin instance to the RDS instance."
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

# ---------------------------------------------------------------------------
# RDS MySQL
# ---------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "${local.name}-db"
  description = "RDS MySQL instance backing phpMyAdmin."
  vpc_id      = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "MySQL ingress from the phpMyAdmin instance only."
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}
