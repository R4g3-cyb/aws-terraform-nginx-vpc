# AWS Hardened Web Infrastructure with Terraform & DevSecOps Auditing

[![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-232F3E?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Security](https://img.shields.io/badge/Audited_by-Trivy-1976D2?logo=aqua&logoColor=white)](https://trivy.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Este repositorio contiene la definición en código (Infrastructure as Code) de una arquitectura web desacoplada y endurecida en Amazon Web Services (AWS), aplicando principios de **Least Privilege**, defensas contra vectores de ataque comunes en la nube (como SSRF hacia metadatos) y auditoría estática de seguridad automatizada con **Trivy**.

---

## 🏛️ Diagrama de Arquitectura

```text
                                     VPC (10.0.0.0/16)
 ┌─────────────────────────────────────────────────────────────────────────────────────────┐
 │                                                                                         │
 │   Internet Gateway                                                                      │
 │          │                                                                              │
 │          ▼                                                                              │
 │   Public Subnet (10.0.1.0/24)                                                           │
 │   ┌─────────────────────────────────────────────────────────────────────────────────┐   │
 │   │                                                                                 │   │
 │   │   Security Group (Ingress: TCP 80/443/22 | Egress: TCP 80/443 only)             │   │
 │   │   ┌─────────────────────────────────────────────────────────────────────────┐   │   │
 │   │   │                                                                         │   │   │
 │   │   │   EC2 Instance (Ubuntu 22.04 LTS / Nginx)                               │   │   │
 │   │   │   ├── IMDSv2 Enforced (Session tokens required, hop-limit=1)            │   │   │
 │   │   │   ├── Root EBS Volume (Encrypted via KMS/AES-256)                       │   │   │
 │   │   │   └── IAM Instance Profile (Least Privilege S3 Access)                  │   │   │
 │   │   │                               │                                         │   │   │
 │   │   └───────────────────────────────┼─────────────────────────────────────────┘   │   │
 │   │                                   │ (ReadOnly API Calls)                        │   │
 │   └───────────────────────────────────┼─────────────────────────────────────────────┘   │
 │                                       │                                                 │
 └───────────────────────────────────────┼─────────────────────────────────────────────────┘
                                         ▼
                 ┌─────────────────────────────────────────────────┐
                 │  Private S3 Bucket (SSE-S3 AES-256 Encrypted)   │
                 │  └── Public Access Block (All 4 flags enabled)  │
                 └─────────────────────────────────────────────────┘
