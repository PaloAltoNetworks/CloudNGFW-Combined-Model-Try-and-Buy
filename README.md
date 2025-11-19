# Cloud NGFW for AWS: Terraform Deployment Guide

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Palo Alto Networks](https://img.shields.io/badge/Palo%20Alto%20Networks-FA582D?style=for-the-badge&logo=paloaltonetworks&logoColor=white)

**Version:** 1.0  
**Date:** November 2025  
**Maintained By:** Salman Syed - Principal TME

---

## 📖 Introduction

This repository contains Terraform code to deploy a **Cloud NGFW for AWS** in a Combined Inspection Model. This architecture delivers comprehensive traffic protection for:

* **North–South (Ingress):** Internet → Application Load Balancer → Workload.
* **North–South (Egress):** Workload → NAT Gateway → Internet.
* **East–West:** VPC-to-VPC lateral movement.

By using this project, you can automate the deployment of AWS networking constructs (VPC, TGW, ALB, Endpoints) while managing the security logic centrally via Palo Alto Networks **Strata Cloud Manager (SCM)**.

## 🏗 Architecture

The deployment creates a central **Security VPC (Hub)** that integrates with an AWS Transit Gateway (TGW) to inspect traffic.

* **Hub:** Handles Egress and East-West inspection.
* **Spokes:** Application VPCs hosting local Cloud NGFW endpoints for Ingress inspection.

![Architecture Diagram](./images/architecture-diagram.png)
*(Note: Ensure you place your architecture diagram in an `images` folder)*

## ✅ Prerequisites

Before running the Terraform code, ensure you have the following:

1.  **AWS Account** with permissions to create VPCs, TGW, EC2, ALB, IGW, and VPC Endpoints.
2.  **Terraform CLI** installed locally (v1.0+).
3.  **AWS EC2 Key Pair** created in your target region (e.g., `prod-dev-key`).
4.  **Strata Cloud Manager (SCM)** access with permissions to manage Cloud NGFW resources.

## 📂 Repository Structure

```text
.
├── main.tf                 # Main entry point
├── tgw.tf                  # Transit Gateway configuration
├── providers.tf            # AWS and Terraform provider definitions
├── variables.tf            # Variable declarations
├── terraform.tfvars        # Input variables (You must create this)
└── modules/
    ├── vpc-app/            # Module for Application Spoke VPCs
    └── vpc-security/       # Module for the Security Hub VPC

Here is the content formatted specifically for a GitHub `README.md` file. I have added syntax highlighting for code blocks, badges, and structured the layout to follow standard open-source repository best practices.

You can copy the raw code block below and paste it directly into your `README.md`.

-----

````markdown
# Cloud NGFW for AWS: Terraform Deployment Guide

![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Palo Alto Networks](https://img.shields.io/badge/Palo%20Alto%20Networks-FA582D?style=for-the-badge&logo=paloaltonetworks&logoColor=white)

**Version:** 1.0  
**Date:** November 2025  
**Maintained By:** Salman Syed - Principal TME

---

## 📖 Introduction

This repository contains Terraform code to deploy a **Cloud NGFW for AWS** in a Combined Inspection Model. This architecture delivers comprehensive traffic protection for:

* **North–South (Ingress):** Internet → Application Load Balancer → Workload.
* **North–South (Egress):** Workload → NAT Gateway → Internet.
* **East–West:** VPC-to-VPC lateral movement.

By using this project, you can automate the deployment of AWS networking constructs (VPC, TGW, ALB, Endpoints) while managing the security logic centrally via Palo Alto Networks **Strata Cloud Manager (SCM)**.

## 🏗 Architecture

The deployment creates a central **Security VPC (Hub)** that integrates with an AWS Transit Gateway (TGW) to inspect traffic.

* **Hub:** Handles Egress and East-West inspection.
* **Spokes:** Application VPCs hosting local Cloud NGFW endpoints for Ingress inspection.

![Architecture Diagram](./images/architecture-diagram.png)
*(Note: Ensure you place your architecture diagram in an `images` folder)*

## ✅ Prerequisites

Before running the Terraform code, ensure you have the following:

1.  **AWS Account** with permissions to create VPCs, TGW, EC2, ALB, IGW, and VPC Endpoints.
2.  **Terraform CLI** installed locally (v1.0+).
3.  **AWS EC2 Key Pair** created in your target region (e.g., `prod-dev-key`).
4.  **Strata Cloud Manager (SCM)** access with permissions to manage Cloud NGFW resources.

## 📂 Repository Structure

```text
.
├── main.tf                 # Main entry point
├── tgw.tf                  # Transit Gateway configuration
├── providers.tf            # AWS and Terraform provider definitions
├── variables.tf            # Variable declarations
├── terraform.tfvars        # Input variables (You must create this)
└── modules/
    ├── vpc-app/            # Module for Application Spoke VPCs
    └── vpc-security/       # Module for the Security Hub VPC
````

-----

## 🚀 Deployment Steps

### Part 1: Strata Cloud Manager (Manual Setup)

⚠️ **Important:** You must create the logical firewall resource in SCM *before* running Terraform.

1.  **Log in to SCM:** Navigate to **Configurations → Cloud NGFWs**.
2.  **Create Firewall:**
      * Select **Amazon Web Services**.
      * Enter Name, Region, AZs, and the **Allowlisted AWS Account ID** (where Terraform will run).
3.  **Retrieve Service Name:**
      * Once deployment shows *Create Complete*, go to **Endpoint Management**.
      * Copy the **VPC Endpoint Service Name** (e.g., `com.amazonaws.vpce.us-east-1.vpce-svc-xxxxx`).
4.  **Push Policy:**
      * Go to **Security Services → Security Policy**.
      * Add a baseline "Allow All" rule (refine later).
      * **Push Config** to the new firewall resource.

### Part 2: Terraform Deployment

1.  **Clone the repository:**

    ```bash
    git clone [https://github.com/your-org/cloud-ngfw-aws-terraform.git](https://github.com/your-org/cloud-ngfw-aws-terraform.git)
    cd cloud-ngfw-aws-terraform
    ```

2.  **Create your variables file:**
    Create a file named `terraform.tfvars` in the root directory and add your specific details:

    ```hcl
    # terraform.tfvars

    # Your existing EC2 Key Pair name
    instance_key_name = "prod-dev-key"

    # The Service Name copied from SCM in Part 1
    gwlb_service_name = "com.amazonaws.vpce.us-east-1.vpce-svc-0677bb49e2ee1b62a"
    ```

3.  **Deploy:**

    ```bash
    # Initialize Terraform
    terraform init

    # Review the plan
    terraform plan

    # Apply the infrastructure
    terraform apply
    ```

    *Type `yes` to confirm.*

-----

## 🧪 Testing & Validation

Once `terraform apply` is complete, use the outputs to validate traffic flows.

### 1\. Ingress Test (Internet → ALB → EC2)

  * **Action:** Copy the `app_vpc_1_alb_dns` from the Terraform output and paste it into a browser.
  * **Expected:** "Hello from ip-10-1-x-x... in application-vpc-1"
  * **Verify:** Check SCM Log Viewer for Ingress traffic logs.

### 2\. Egress Test (EC2 → Internet)

  * **Action:** SSH into a private EC2 instance (via Bastion or SSM) and run:
    ```bash
    curl -v [http://www.google.com](http://www.google.com)
    ```
  * **Expected:** HTTP 200 OK response.
  * **Verify:** Check SCM Log Viewer for Egress traffic logs.

### 3\. East-West Test (VPC A → VPC B)

  * **Action:** From an EC2 in App VPC 1, ping an instance in App VPC 2:
    ```bash
    ping 10.2.x.x
    ```
  * **Expected:** Successful ICMP replies.
  * **Verify:** Check SCM Log Viewer for East-West traffic logs.

-----

## 🧹 Cleanup

To remove all resources created by this project and avoid AWS charges:

```bash
terraform destroy
```

*Note: You must also manually delete the Cloud NGFW resource in SCM after the Terraform destroy is complete.*

-----

## 📝 License & Support

**Corporate Headquarters:** Palo Alto Networks  
3000 Tannery Way, Santa Clara, CA 95054

For documentation, visit [docs.paloaltonetworks.com](https://docs.paloaltonetworks.com).

© 2025 Palo Alto Networks, Inc.

```
```
