output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.mi_vpc.id
}

output "public_ip" {
  description = "IP publica de la instancia EC2 para acceder a Nginx"
  value       = aws_instance.servidor_prueba.public_ip
}

output "url_servidor" {
  description = "URL lista para copiar y pegar en el navegador"
  value       = "http://${aws_instance.servidor_prueba.public_ip}"
}