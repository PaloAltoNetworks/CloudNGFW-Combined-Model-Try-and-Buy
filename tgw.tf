# Root tgw.tf

resource "aws_ec2_transit_gateway" "main" {
  description                     = "Central Transit Gateway"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = "central-tgw"
  }
}

# --- We now need 3 TGW Route Tables for this model ---

# TGW Route Table for Application VPC 1
resource "aws_ec2_transit_gateway_route_table" "app_1" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags = {
    Name = "App-1-TGW-RT"
  }
}

# TGW Route Table for Application VPC 2
resource "aws_ec2_transit_gateway_route_table" "app_2" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags = {
    Name = "App-2-TGW-RT"
  }
}

# TGW Route Table for Security VPC
resource "aws_ec2_transit_gateway_route_table" "security" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags = {
    Name = "Security-TGW-RT"
  }
}

# --- TGW Routes ---
# All VPC-to-VPC and Private Subnet Egress traffic is forced through the Security VPC attachment for inspection.

# App 1 RT: Routes to App 2, Security VPC, and Internet (via Security VPC)
resource "aws_ec2_transit_gateway_route" "app_1_to_app_2" {
  destination_cidr_block         = "10.2.0.0/16" # App 2 CIDR
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.app_1.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
}
resource "aws_ec2_transit_gateway_route" "app_1_to_security" {
  destination_cidr_block         = "10.0.0.0/16" # Security VPC CIDR
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.app_1.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
}
resource "aws_ec2_transit_gateway_route" "app_1_default" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.app_1.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
}


# App 2 RT: Routes to App 1, Security VPC, and Internet (via Security VPC)
resource "aws_ec2_transit_gateway_route" "app_2_to_app_1" {
  destination_cidr_block         = "10.1.0.0/16" # App 1 CIDR
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.app_2.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
}
resource "aws_ec2_transit_gateway_route" "app_2_to_security" {
  destination_cidr_block         = "10.0.0.0/16" # Security VPC CIDR
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.app_2.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
}
resource "aws_ec2_transit_gateway_route" "app_2_default" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.app_2.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.security.id
}


# Security RT: Routes back to App VPCs (after inspection)
resource "aws_ec2_transit_gateway_route" "security_to_app_1" {
  destination_cidr_block         = "10.1.0.0/16" # App 1 CIDR
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app_1.id
}
resource "aws_ec2_transit_gateway_route" "security_to_app_2" {
  destination_cidr_block         = "10.2.0.0/16" # App 2 CIDR
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security.id
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app_2.id
}
