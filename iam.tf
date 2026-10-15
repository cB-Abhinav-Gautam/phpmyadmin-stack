# ---------------------------------------------------------------------------
# phpMyAdmin instance role: SSM Session Manager, ECR pull, and read of the
# RDS-managed master password secret. No IAM users, no access keys.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "app_assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${local.name}-instance-role"
  description        = "Role for the phpMyAdmin instance: SSM access, ECR pull, read of the DB master secret."
  assume_role_policy = data.aws_iam_policy_document.app_assume_role.json
}

resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "app_ecr_read" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy_document" "app_secret_read" {
  statement {
    sid    = "ReadDatabaseMasterSecret"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_db_instance.mysql.master_user_secret[0].secret_arn]
  }

  statement {
    sid    = "DecryptWithStackKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.stack.arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "secretsmanager.${data.aws_region.current.name}.amazonaws.com",
        "ecr.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "app_secret_read" {
  name   = "${local.name}-read-db-secret"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.app_secret_read.json
}

resource "aws_iam_instance_profile" "app" {
  name = "${local.name}-instance-profile"
  role = aws_iam_role.app.name
}

# ---------------------------------------------------------------------------
# RDS enhanced monitoring role
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "rds_monitoring_assume_role" {
  statement {
    sid     = "RDSMonitoringAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_monitoring" {
  name               = "${local.name}-rds-monitoring"
  description        = "Allows RDS to publish enhanced monitoring metrics to CloudWatch."
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume_role.json
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
