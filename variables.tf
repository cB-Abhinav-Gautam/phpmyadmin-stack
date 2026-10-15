variable "aws_region" {
  description = "AWS region to deploy the phpMyAdmin stack into."
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name applied as a default tag to every resource."
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owning team applied as a default tag to every resource."
  type        = string
  default     = "platform-team"
}

variable "name_prefix" {
  description = "Prefix used for the names of all resources in this stack."
  type        = string
  default     = "phpmyadmin"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC hosting phpMyAdmin and its database."
  type        = string
  default     = "10.40.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4 so that Multi-AZ RDS can be placed."
  }
}

variable "instance_type" {
  description = "EC2 instance type running the phpMyAdmin container."
  type        = string
  default     = "t3.small"
}

variable "phpmyadmin_image_tag" {
  description = "Tag of the phpMyAdmin image in the stack's private ECR repository."
  type        = string
  default     = "5.2-apache"
}

variable "phpmyadmin_port" {
  description = "Loopback port on the instance that phpMyAdmin listens on. Reached through an SSM port-forwarding session."
  type        = number
  default     = 8080
}

variable "db_engine_version" {
  description = "MySQL engine version for the RDS instance."
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "Instance class for the RDS MySQL instance."
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage in GiB for the RDS instance."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Upper bound in GiB for RDS storage autoscaling."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the initial database created on the RDS instance."
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the RDS instance. The password is generated and stored in Secrets Manager by RDS."
  type        = string
  default     = "pmaadmin"
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated RDS backups. Must be greater than zero."
  type        = number
  default     = 7

  validation {
    condition     = var.db_backup_retention_period > 0
    error_message = "db_backup_retention_period must be greater than 0 so that automated backups stay enabled."
  }
}

variable "log_retention_in_days" {
  description = "Retention for CloudWatch log groups created by this stack."
  type        = number
  default     = 365

  validation {
    condition     = var.log_retention_in_days >= 365
    error_message = "log_retention_in_days must be at least 365."
  }
}

variable "kms_deletion_window_in_days" {
  description = "Waiting period before the stack KMS key is deleted."
  type        = number
  default     = 30
}
