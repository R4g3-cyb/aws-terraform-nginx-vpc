# 🌐 Modular AWS Web Infrastructure Deployment with Terraform

## 📌 Project Overview
This project provisions a secure and automated web server infrastructure on **Amazon Web Services (AWS)** using **Terraform** (IaC).

This iteration adopts professional Infrastructure as Code standards by **decoupling configuration from logic** through modular file architecture (`variables.tf` and `outputs.tf`), eliminating hardcoded parameters and automating endpoint exposure.

---

## 🛠️ Project Structure
```text
├── main.tf        # Core infrastructure and resource definitions
├── variables.tf   # Parametrized inputs (CIDR blocks, AMI, instance type)
├── outputs.tf     # Exposed deployment data (VPC ID, public IP, server URL)
└── img/           # Deployment screenshots and architectural proof

🏗️ Resources Provisioned

    VPC & Networking: Custom VPC (10.0.0.0/16), Public Subnet, Internet Gateway, and Route Table.

    Security Group: Inbound rules strictly limited to HTTP (80) and SSH (22); unrestricted outbound.

    Compute: EC2 instance (t3.micro / Ubuntu 22.04 LTS) bootstrapped automatically via user_data to install and run Nginx.

    Outputs: Direct console rendering of VPC IDs and formatted URL endpoints upon deployment.

🔐 Engineering & Security Highlights

    Dry/Modular Configuration: Replaced static values with explicit types and variable descriptions for cross-environment portability.

    Automated Bootstrapping: Provisioned runtime software stack using startup scripts without manual SSH intervention.

    Stateless & Cost-Conscious: Zero ongoing cloud expense guaranteed by full verification of lifecycle commands (apply and destroy).

📸 Deployment Evidence

Nginx web server responding directly via public HTTP endpoint.
🚀 Execution Guide
Bash

# 1. Initialize provider plugins
terraform init

# 2. Plan and apply infrastructure
terraform plan
terraform apply -auto-approve

# 3. Destroy resources after testing to maintain $0 spend
terraform destroy -auto-approve
