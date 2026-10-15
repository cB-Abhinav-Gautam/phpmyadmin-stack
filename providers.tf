provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      owner       = var.owner
      environment = var.environment
      stack       = var.name_prefix
      managed-by  = "apex-opentofu"
    }
  }
}
