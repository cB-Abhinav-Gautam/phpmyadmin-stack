output "vpc_id" {
  description = "ID of the VPC hosting the phpMyAdmin stack."
  value       = module.vpc.vpc_id
}

output "instance_id" {
  description = "Instance ID of the phpMyAdmin host. Use this to open an SSM port-forwarding session."
  value       = aws_instance.phpmyadmin.id
}

output "db_endpoint" {
  description = "Endpoint of the RDS MySQL instance backing phpMyAdmin."
  value       = aws_db_instance.mysql.endpoint
}

output "db_master_secret_arn" {
  description = "ARN of the Secrets Manager secret holding the RDS master credentials."
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}

output "ecr_repository_url" {
  description = "Private ECR repository the phpMyAdmin image must be mirrored into before the instance can start."
  value       = aws_ecr_repository.phpmyadmin.repository_url
}

output "kms_key_arn" {
  description = "ARN of the customer-managed key used across the stack."
  value       = aws_kms_key.stack.arn
}

output "port_forward_command" {
  description = "Command that opens phpMyAdmin on http://localhost:8080 through SSM."
  value       = "aws ssm start-session --target ${aws_instance.phpmyadmin.id} --region ${var.aws_region} --document-name AWS-StartPortForwardingSession --parameters '{\"portNumber\":[\"${var.phpmyadmin_port}\"],\"localPortNumber\":[\"${var.phpmyadmin_port}\"]}'"
}
