output "sg_id" {
  description = "ID del security group creado"
  value       = aws_security_group.this.id
}