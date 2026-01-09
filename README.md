

## Introduction

This repository contains Terraform code to deploy a **Cloud NGFW for AWS** in a Combined Inspection Model. This architecture delivers comprehensive traffic protection for:

* **North–South (Ingress):** Internet → Application Load Balancer → Workload.
* **North–South (Egress):** Workload → NAT Gateway → Internet.
* **East–West:** VPC-to-VPC lateral movement.

By using this project, you can automate the deployment of AWS networking constructs (VPC, TGW, ALB, Endpoints) while managing the security logic centrally via Palo Alto Networks **Strata Cloud Manager (SCM)**.


The deployment creates a central **Security VPC (Hub)** that integrates with an AWS Transit Gateway (TGW) to inspect traffic.

* **Hub:** Handles Egress and East-West inspection.
* **Spokes:** Application VPCs hosting local Cloud NGFW endpoints for Ingress inspection.


## Prerequisites

Before running the Terraform code, ensure you have the following:

1.  **AWS Account** with permissions to create VPCs, TGW, EC2, ALB, IGW, and VPC Endpoints.
2.  **Terraform CLI** installed locally (v1.0+).
3.  **AWS EC2 Key Pair** created in your target region (e.g., `prod-dev-key`).
4.  **Strata Cloud Manager (SCM)** access with permissions to manage Cloud NGFW resources.

## Deployment Guide

For complete instructions, please follow the guide here

https://live.paloaltonetworks.com/t5/cloud-ngfw-for-aws-articles/cloud-ngfw-for-aws-scm-try-and-buy-deployment-guide-with/ta-p/1243010



## License & Support

**Corporate Headquarters:** Palo Alto Networks  
3000 Tannery Way, Santa Clara, CA 95054

For documentation, visit [docs.paloaltonetworks.com](https://docs.paloaltonetworks.com).

© 2025 Palo Alto Networks, Inc.

```
```
