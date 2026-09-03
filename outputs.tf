output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.vpc_principal.id
}

output "instancia_ip_publica" {
  description = "IP publica del servidor web"
  value       = aws_instance.servidor_prueba.public_ip
}

output "bucket_s3_arn" {
  description = "ARN del bucket cifrado"
  value       = aws_s3_bucket.bucket_privado.arn
}

output "bucket_encryption_status" {
  description = "Algoritmo de cifrado aplicado en S3"
  value       = one(aws_s3_bucket_server_side_encryption_configuration.cifrado_s3.rule).apply_server_side_encryption_by_default[0].sse_algorithm
}