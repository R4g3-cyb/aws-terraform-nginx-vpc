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

# ==========================================
# 1. NETWORKING (VPC, Subnet, IGW, Route Table)
# ==========================================

resource "aws_vpc" "vpc_principal" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC-Hardened"
  }
}

resource "aws_subnet" "subred_publica" {
  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "Subred-Publica-Hardened"
  }
}

resource "aws_internet_gateway" "igw_principal" {
  vpc_id = aws_vpc.vpc_principal.id

  tags = {
    Name = "IGW-Principal"
  }
}

resource "aws_route_table" "tabla_publica" {
  vpc_id = aws_vpc.vpc_principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_principal.id
  }

  tags = {
    Name = "Tabla-Rutas-Publica"
  }
}

resource "aws_route_table_association" "asociacion_subred" {
  subnet_id      = aws_subnet.subred_publica.id
  route_table_id = aws_route_table.tabla_publica.id
}

# ==========================================
# 2. SECURITY GROUP (SSH Restringido + HTTP)
# ==========================================

resource "aws_security_group" "sg_servidor" {
  name        = "sg_servidor_hardened"
  description = "Trafico HTTP publico y SSH restringido por IP"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    description = "HTTP publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HARDENING: Puerto 22 no expuesto a 0.0.0.0/0
  ingress {
    description = "SSH exclusivo para IP de administracion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.mi_ip]
  }

  #trivy:ignore:AVD-AWS-0104 Egress permitido a internet exclusivamente para repositorios y parches
  egress {
    description = "HTTPS para paquetes"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #trivy:ignore:AVD-AWS-0104 Egress permitido a internet exclusivamente para repositorios y parches
  egress {
    description = "HTTP para paquetes"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Hardened"
  }
}

# ==========================================
# 3. S3 BUCKET (Hardening: Block Public + Encryption + Versioning)
# ==========================================

resource "aws_s3_bucket" "bucket_privado" {
  bucket_prefix = "lab-seguro-hardened-"
  force_destroy = true

  tags = {
    Name        = "S3-Hardened-Bucket"
    Environment = "DevSecOps"
  }
}

# Bloqueo total de acceso público
resource "aws_s3_bucket_public_access_block" "bloqueo_publico_s3" {
  bucket = aws_s3_bucket.bucket_privado.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# HARDENING: Cifrado en reposo obligatorio (SSE-S3 / AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "cifrado_s3" {
  bucket = aws_s3_bucket.bucket_privado.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# HARDENING: Versionado activado
resource "aws_s3_bucket_versioning" "versionado_s3" {
  bucket = aws_s3_bucket.bucket_privado.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ==========================================
# 4. IAM (Least Privilege Role + Instance Profile)
# ==========================================

resource "aws_iam_role" "rol_ec2_s3" {
  name = "rol_ec2_lectura_s3_hardened"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "IAM-Role-EC2-S3-LeastPrivilege"
  }
}

resource "aws_iam_policy" "politica_lectura_s3" {
  name        = "politica_lectura_s3_estricta"
  description = "Permite solo GetObject y ListBucket en el bucket especifico"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.bucket_privado.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.bucket_privado.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "adjuntar_politica" {
  role       = aws_iam_role.rol_ec2_s3.name
  policy_arn = aws_iam_policy.politica_lectura_s3.arn
}

resource "aws_iam_instance_profile" "perfil_instancia_ec2" {
  name = "perfil_instancia_ec2_hardened"
  role = aws_iam_role.rol_ec2_s3.name
}

# ==========================================
# 5. CÓMPUTO (EC2 con EBS Cifrado e Instance Profile)
# ==========================================

resource "aws_instance" "servidor_prueba" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subred_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_servidor.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.perfil_instancia_ec2.name
 
 # REMEDIACIÓN AWS-0028: Bloquear IMDSv1
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # HARDENING: Cifrado en el disco raíz EBS
  root_block_device {
    encrypted   = true
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = <<-EOF
              #!/bin/bash
              sleep 30
              apt-get update -y
              apt-get install -y nginx awscli
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Infraestructura AWS Hardened con Terraform - DevSecOps Lab</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "EC2-Hardened-IaC"
  }
}