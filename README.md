# 🌐 Automated Web Server Deployment with Terraform (VPC, EC2 & Nginx User Data)

## 📌 Project Overview
This project demonstrates the automated provisioning of cloud infrastructure on **Amazon Web Services (AWS)** using **Terraform** (Infrastructure as Code).

Building upon the previous VPC configuration, this iteration automates the bootstrap process of an **EC2 instance** to install, configure, and launch an **Nginx Web Server** at launch time using `user_data` scripts.

---

## 🛠️ Architecture & Resources Provisioned
The `main.tf` script deploys the following resources in `us-east-1`:

1. **Virtual Private Cloud (VPC):** Custom CIDR `10.0.0.0/16`.
2. **Internet Gateway & Route Table:** Enables outbound/inbound public internet connectivity.
3. **Public Subnet (`10.0.1.0/24`):** Subnet configured with auto-assign public IP enabled.
4. **Security Group (`sg_servidor_web`):** Firewall allowing inbound traffic on **Port 80 (HTTP)** and **Port 22 (SSH)**.
5. **EC2 Instance (`t3.micro`):** Ubuntu 22.04 LTS server.
6. **Automated Bootstrap (`user_data`):** Bash script executed during launch to update packages, install Nginx, enable the service, and serve a custom HTML page.
7. **Terraform Outputs:** Configured to expose the public IP address upon deployment.

---

## 🔐 Security & Engineering Practices
- **Automated Provisioning:** Eliminated manual server configuration by embedding shell scripts into IaC lifecycle.
- **Data Sanitization:** Masked sensitive AWS Account IDs in all published documentation.
- **Stateless Infrastructure:** Verified clean lifecycle management via `terraform apply` and immediate tear-down using `terraform destroy` to maintain $0 cloud expenses.

---

## 📸 Deployment Evidence

### Nginx Web Server Output via HTTP
![Nginx Web Page](./img/nginx-web.png)
*Shows the active web page rendered by Nginx, confirming proper Security Group routing and successful execution of the user_data script.*

---

## 🚀 How to Run
1. Clone the repository:
   ```bash
   git clone <repo-url>

    Ensure AWS credentials are set up locally (~/.aws/credentials).

    Deploy the infrastructure:

    terraform init
    terraform apply

    Access the server in your browser using the outputted IP: http://<PUBLIC_IP>

    Destroy all resources:
   
    terraform destroy
