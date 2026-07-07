output "endpoint" {
  value = aws_db_instance.this.endpoint
}

output "address" {
  value = aws_db_instance.this.address
}

output "port" {
  value = local.port
}

output "security_group_id" {
  value = aws_security_group.rds.id
}

output "db_instance_id" {
  value = aws_db_instance.this.id
}
