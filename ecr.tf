# Private registry holding a mirrored copy of the upstream phpMyAdmin image.
# The VPC has no internet egress, so the image must be pulled from here.
resource "aws_ecr_repository" "phpmyadmin" {
  name                 = "${local.name}/phpmyadmin"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.stack.arn
  }
}

resource "aws_ecr_lifecycle_policy" "phpmyadmin" {
  repository = aws_ecr_repository.phpmyadmin.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the 10 most recent images."
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
