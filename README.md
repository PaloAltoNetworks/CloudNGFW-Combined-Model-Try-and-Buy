# Terraform Combined Deployment  Model

This project deploys a complex, modular "hCombined Deployment Model"  on AWS using Terraform. It creates two "Application VPCs" and one "Security VPC," all connected via a Transit Gateway (TGW).

This architecture implements a Combinedinspection model:
1.  **North-South (Internet) Traffic:** Is handled and inspected **locally** within each Application VPC. Traffic to/from the internet is routed through a local NGFW Endpoint and IGW.
2.  **East-West (VPC-to-VPC) & Private Egress Traffic:** Is inspected **centrally**. All traffic from private subnets (to the internet) and all traffic between VPCs is routed to the TGW, which forces it through a central NGFW Endpoint in the Security VPC for inspection.


## How to Deploy

### Step 1: Create `terraform.tfvars`

In the root directory of the project, create a file named `terraform.tfvars`. This file will hold your environment-specific secrets and IDs.

Copy and paste the following into `terraform.tfvars`, and replace the values with your own:

```hcl
# Your AWS EC2 Key Pair name for SSH access
instance_key_name = "your-ec2-key-name"

# The VPC Endpoint Service Name for your GWLB
# Find this in the AWS Console -> VPC -> Endpoint Services
# It looks like: com.amazonaws.vpce.us-east-1.vpce-svc-xxxxxxxxxxxxxxxxx
gwlb_service_name = "com.amazonaws.vpce.us-east-1.vpce-svc-xxxxxxxxxxxxxxxxx"
