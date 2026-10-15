# Written as a native resource rather than the registry module so that the
# security group attachment is visible to static analysis (CKV2_AWS_5), which
# cannot see through an un-downloaded external module.
resource "aws_db_instance" "mysql" {
  identifier = "${local.name}-mysql"

  engine                     = "mysql"
  engine_version             = var.db_engine_version
  instance_class             = var.db_instance_class
  auto_minor_version_upgrade = true

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.stack.arn

  db_name  = var.db_name
  username = var.db_username
  port     = 3306

  # RDS generates the master password and stores it in Secrets Manager under the
  # stack key. No password is ever rendered into state or into user data.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.stack.arn

  multi_az               = true
  publicly_accessible    = false
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db.id]

  iam_database_authentication_enabled = true

  backup_retention_period   = var.db_backup_retention_period
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name}-mysql-final"
  deletion_protection       = true

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.stack.arn
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Name = "${local.name}-mysql"
  }
}
