output "db_endpoint" {
  description = "RDS instance endpoint (hostname:port)"
  value       = aws_db_instance.backstage.endpoint
}

output "db_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.backstage.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.backstage.port
}

output "db_security_group_id" {
  description = "Security group ID for the RDS instance"
  value       = aws_security_group.rds.id
}
