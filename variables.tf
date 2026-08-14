variable "region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Rango CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Rango CIDR para la subred pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI de Ubuntu 22.04 LTS para us-east-1"
  type        = string
  default     = "ami-04a81a99f5ec58529"
}