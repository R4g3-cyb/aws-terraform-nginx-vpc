terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# 1. VPC
resource "aws_vpc" "mi_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "VPC-Modular-Martes"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "mi_igw" {
  vpc_id = aws_vpc.mi_vpc.id
  tags = {
    Name = "IGW-Modular-Martes"
  }
}

# 3. Subred Pública
resource "aws_subnet" "subred_publica" {
  vpc_id                  = aws_vpc.mi_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-Publica-Modular"
  }
}

# 4. Tabla de Ruteo
resource "aws_route_table" "tabla_publica" {
  vpc_id = aws_vpc.mi_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mi_igw.id
  }

  tags = {
    Name = "RouteTable-Publica-Modular"
  }
}

# 5. Asociación de Tabla de Ruteo
resource "aws_route_table_association" "asociacion_publica" {
  subnet_id      = aws_subnet.subred_publica.id
  route_table_id = aws_route_table.tabla_publica.id
}

# 6. Security Group
resource "aws_security_group" "sg_servidor" {
  name        = "sg_servidor_web_modular"
  description = "Permitir trafico SSH y HTTP"
  vpc_id      = aws_vpc.mi_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Servidor-Web-Modular"
  }
}

# 7. Instancia EC2 con Nginx
resource "aws_instance" "servidor_prueba" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subred_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_servidor.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              sleep 30
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Servidor Web Modularizado con Terraform - Clase Martes</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "EC2-Servidor-Modular"
  }
}