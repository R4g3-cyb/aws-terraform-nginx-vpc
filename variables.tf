variable "region" {
  description = "Región de AWS para el despliegue"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Bloque CIDR para la subred pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Zona de disponibilidad para la subred"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI de Ubuntu 22.04 LTS para us-east-1"
  type        = string
  default     = "ami-0c7217cdde317cfec"
}

variable "mi_ip" {
  description = "Tu IP pública para restringir el acceso SSH (formato CIDR, ej: 181.44.xx.xx/32)"
  type        = string
  default     = "181.44.0.1/32" # Podés dejarla por defecto o cambiarla por tu IP pública
}