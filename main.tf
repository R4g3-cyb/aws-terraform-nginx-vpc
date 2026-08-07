terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. VPC
resource "aws_vpc" "mi_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC-Clase-Martes"
  }
}

# 2. Internet Gateway
resource "aws_internet_gateway" "mi_igw" {
  vpc_id = aws_vpc.mi_vpc.id
  tags = {
    Name = "IGW-Clase-Martes"
  }
}

# 3. Subred Pública
resource "aws_subnet" "subred_publica" {
  vpc_id                  = aws_vpc.mi_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-Publica-Martes"
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
    Name = "RouteTable-Publica"
  }
}

# 5. Asociación de Tabla de Ruteo
resource "aws_route_table_association" "asociacion_publica" {
  subnet_id      = aws_subnet.subred_publica.id
  route_table_id = aws_route_table.tabla_publica.id
}

# 6. Grupo de Seguridad (Firewall virtual)
resource "aws_security_group" "sg_servidor" {
  name        = "sg_servidor_web"
  description = "Permitir trafico SSH y HTTP"
  vpc_id      = aws_vpc.mi_vpc.id

  # Entrada HTTP (Puerto 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Entrada SSH (Puerto 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida hacia internet (Egress irrestricto)
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "SG-Servidor-Web"
  }
}

# 7. Instancia EC2 con script de arranque corregido
resource "aws_instance" "servidor_prueba" {
  ami           = "ami-04a81a99f5ec58529" # Ubuntu 22.04 LTS
  instance_type = "t3.micro"

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
              echo "<h1>Servidor Web desplegado con Terraform - Clase Martes</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "EC2-Servidor-Web-Nginx"
  }
}