terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==============================================================================
# RED Y VPC
# ==============================================================================

resource "aws_vpc" "vpc_principal" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC-Principal-Hardened"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc_principal.id
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

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_principal.id

  tags = {
    Name = "IGW-Principal"
  }
}

resource "aws_route_table" "tabla_ruteo_publica" {
  vpc_id = aws_vpc.vpc_principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Tabla-Ruteo-Publica"
  }
}

resource "aws_route_table_association" "asociacion_publica" {
  subnet_id      = aws_subnet.subred_publica.id
  route_table_id = aws_route_table.tabla_ruteo_publica.id
}

# ==============================================================================
# SEGURIDAD Y FIREWALLING (SECURITY GROUPS)
# ==============================================================================

resource "aws_security_group" "sg_servidor" {
  name        = "sg-servidor-web"
  description = "Security Group endurecido para servidor web"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    description = "Acceso HTTP publico"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida HTTP para descargas y paquetes"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida HTTPS para actualizaciones de repositorios"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Servidor-Web"
  }
}

# ==============================================================================
# ALMACENAMIENTO (S3 BUCKET HARDENED)
# ==============================================================================

resource "aws_s3_bucket" "bucket_privado" {
  bucket_prefix = "lab-privado-hardened-"
  force_destroy = true

  tags = {
    Name        = "Bucket-Privado-Hardened"
    Environment = "DevSecOps"
  }
}

resource "aws_s3_bucket_public_access_block" "bloqueo_publico_s3" {
  bucket = aws_s3_bucket.bucket_privado.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cifrado_s3" {
  bucket = aws_s3_bucket.bucket_privado.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "versionado_s3" {
  bucket = aws_s3_bucket.bucket_privado.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ==============================================================================
# COMPUTO (EC2 HARDENED + IMDSv2)
# ==============================================================================

data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "servidor_prueba" {
  ami                         = data.aws_ami.ubuntu_latest.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subred_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_servidor.id]
  associate_public_ip_address = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "Servidor-Prueba-Hardened"
  }
}