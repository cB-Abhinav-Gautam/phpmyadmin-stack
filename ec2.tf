data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "phpmyadmin" {
  ami           = nonsensitive(data.aws_ssm_parameter.al2023.value)
  instance_type = var.instance_type

  # Private subnet, no public address, no inbound security group rules.
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false

  iam_instance_profile = aws_iam_instance_profile.app.name

  monitoring    = true
  ebs_optimized = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    kms_key_id            = aws_kms_key.stack.arn
    delete_on_termination = true
  }

  user_data_replace_on_change = true
  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    region          = data.aws_region.current.name
    registry        = split("/", aws_ecr_repository.phpmyadmin.repository_url)[0]
    image_uri       = "${aws_ecr_repository.phpmyadmin.repository_url}:${var.phpmyadmin_image_tag}"
    db_host         = aws_db_instance.mysql.address
    db_port         = 3306
    phpmyadmin_port = var.phpmyadmin_port
  }))

  # The SSM agent needs its endpoints before user data can authenticate to ECR.
  depends_on = [
    aws_vpc_endpoint.interface,
    aws_vpc_endpoint.s3
  ]

  tags = {
    Name = "${local.name}-app"
  }
}
