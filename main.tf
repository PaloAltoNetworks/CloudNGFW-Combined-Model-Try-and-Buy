# Root main.tf: Orchestrates all VPCs and TGW attachments

# -----------------------------------------------------------------------------
# 1. Application VPC 1
# -----------------------------------------------------------------------------
module "app_vpc_1" {
  source                      = "./modules/vpc-app"
  name                        = "application-vpc-1"
  vpc_cidr                    = "10.1.0.0/16"
  public_subnet_cidrs         = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs        = ["10.1.3.0/24", "10.1.4.0/24"]
  firewall_subnet_cidrs       = var.firewall_subnet_cidrs_app_1
  tgw_attachment_subnet_cidrs = ["10.1.5.0/28", "10.1.6.0/28"]
  availability_zones          = var.availability_zones
  instance_key_name           = var.instance_key_name
  ec2_instance_type           = var.ec2_instance_type
  ec2_tags = {
    "Ccoe-app"  = "Cloud-ngfw"
    "Ccoe-group" = "pm-tme"
    "Userid"    = "seed"
    "Runstatus" = "no stop"
  }
  security_vpc_cidr  = "10.0.0.0/16"
  other_app_vpc_cidr = "10.2.0.0/16" # <-- CIDR for App VPC 2
  tgw_id             = aws_ec2_transit_gateway.main.id
  gwlb_service_name  = var.gwlb_service_name
}

# -----------------------------------------------------------------------------
# 2. Application VPC 2
# -----------------------------------------------------------------------------
module "app_vpc_2" {
  source                      = "./modules/vpc-app"
  name                        = "application-vpc-2"
  vpc_cidr                    = "10.2.0.0/16"
  public_subnet_cidrs         = ["10.2.1.0/24", "10.2.2.0/24"]
  private_subnet_cidrs        = ["10.2.3.0/24", "10.2.4.0/24"]
  firewall_subnet_cidrs       = var.firewall_subnet_cidrs_app_2
  tgw_attachment_subnet_cidrs = ["10.2.5.0/28", "10.2.6.0/28"]
  availability_zones          = var.availability_zones
  instance_key_name           = var.instance_key_name
  ec2_instance_type           = var.ec2_instance_type
  ec2_tags = {
    "Ccoe-app"  = "Cloud-ngfw"
    "Ccoe-group" = "pm-tme"
    "Userid"    = "seed"
    "Runstatus" = "no stop"
  }
  security_vpc_cidr  = "10.0.0.0/16"
  other_app_vpc_cidr = "10.1.0.0/16" # <-- CIDR for App VPC 1
  tgw_id             = aws_ec2_transit_gateway.main.id
  gwlb_service_name  = var.gwlb_service_name
}

# -----------------------------------------------------------------------------
# 3. Security VPC
# -----------------------------------------------------------------------------
module "security_vpc" {
  source                         = "./modules/vpc-security"
  name                           = "security-vpc"
  vpc_cidr                       = "10.0.0.0/16"
  firewall_endpoint_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  nat_gw_subnet_cidrs            = ["10.0.3.0/24", "10.0.4.0/24"]
  tgw_attachment_subnet_cidrs    = ["10.0.5.0/28", "10.0.6.0/28"]
  availability_zones             = var.availability_zones
  app_vpc_1_cidr                 = module.app_vpc_1.vpc_cidr
  app_vpc_2_cidr                 = module.app_vpc_2.vpc_cidr
  tgw_id                         = aws_ec2_transit_gateway.main.id
  gwlb_service_name              = var.gwlb_service_name # Pass GWLB service to Security VPC
}

# -----------------------------------------------------------------------------
# 4. TGW Attachments and Routing
# -----------------------------------------------------------------------------

# TGW Attachment for Application VPC 1
resource "aws_ec2_transit_gateway_vpc_attachment" "app_1" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = module.app_vpc_1.vpc_id
  subnet_ids         = module.app_vpc_1.tgw_subnet_ids
  tags               = { Name = "app-1-attachment" }
  transit_gateway_default_route_table_association = false
}
resource "aws_ec2_transit_gateway_route_table_association" "app_1" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.app_1.id # Use App 1 RT
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app_1.id
}

# TGW Attachment for Application VPC 2
resource "aws_ec2_transit_gateway_vpc_attachment" "app_2" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = module.app_vpc_2.vpc_id
  subnet_ids         = module.app_vpc_2.tgw_subnet_ids
  tags               = { Name = "app-2-attachment" }
  transit_gateway_default_route_table_association = false
}
resource "aws_ec2_transit_gateway_route_table_association" "app_2" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.app_2.id # Use App 2 RT
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app_2.id
}

# TGW Attachment for Security VPC (The Hub)
resource "aws_ec2_transit_gateway_vpc_attachment" "security" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = module.security_vpc.vpc_id
  subnet_ids         = module.security_vpc.tgw_subnet_ids
  tags               = { Name = "security-vpc-attachment" }
  appliance_mode_support = "enable"
  transit_gateway_default_route_table_association = false
}
resource "aws_ec2_transit_gateway_route_table_association" "security" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
}

# --- Outputs for Verification ---

output "app_vpc_1_alb_dns" {
  description = "DNS name of the ALB in Application VPC 1"
  value       = module.app_vpc_1.alb_dns_name
}

output "app_vpc_2_alb_dns" {
  description = "DNS name of the ALB in Application VPC 2"
  value       = module.app_vpc_2.alb_dns_name
}
