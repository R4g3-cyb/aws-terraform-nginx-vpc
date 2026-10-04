variable "vpc_id" {
  description = "ID de la VPC donde se crea el SG"
  type        = string
}

variable "allowed_ip" {
  description = "IP permitida para SSH (sin el /32)"
  type        = string
}

variable "sg_name" {
  description = "Nombre del security group"
  type        = string
}