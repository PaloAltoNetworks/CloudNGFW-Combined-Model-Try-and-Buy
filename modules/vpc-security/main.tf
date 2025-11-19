# modules/vpc-security/main.tf

# 1. VPC and IGW
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = var.name,
    Environment = "Security"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "${var.name}-igw" }
}

# 2. Firewall Endpoint Subnets (Private)
resource "aws_subnet" "firewall_endpoint" {
  count             = length(var.firewall_endpoint_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.firewall_endpoint_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "${var.name}-fw-endpoint-subnet-${count.index + 1}" }
}

# --- GWLB ENDPOINTS (Central) ---
resource "aws_vpc_endpoint" "gwlb" {
  count             = length(var.firewall_endpoint_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  service_name      = var.gwlb_service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  subnet_ids        = [aws_subnet.firewall_endpoint[count.index].id]

  tags = {
    Name = "${var.name}-gwlb-endpoint-${count.index + 1}"
  }
}

# --- LOCAL MAPS TO FIX ROUTING ---
locals {
  # Map AZ (e.g., "us-east-1a") to its GWLB ENI
  gwlb_eni_per_az = {
    for i, endpoint in aws_vpc_endpoint.gwlb :
    aws_subnet.firewall_endpoint[i].availability_zone => one(endpoint.network_interface_ids)
  }

  # Map NAT GW route tables (by index) to their AZ
  nat_gw_rt_az_map = {
    for i, subnet in aws_subnet.nat_gw :
    i => subnet.availability_zone
  }

  # Map TGW route tables (by index) to their AZ
  tgw_rt_az_map = {
    for i, subnet in aws_subnet.tgw_attachment :
    i => subnet.availability_zone
  }
}

# Dedicated Route Tables for Firewall Endpoint Subnets
# Per your request: "Endpoint subnet ... default route to NATgw and VPC 1 and 2 route to TGW"
resource "aws_route_table" "firewall_endpoint" {
  count  = length(aws_subnet.firewall_endpoint)
  vpc_id = aws_vpc.main.id

  # Route for 0.0.0.0/0 (inspected egress) goes to the NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  # Route for App VPC 1 (inspected E-W) goes to TGW
  route {
    cidr_block         = var.app_vpc_1_cidr
    transit_gateway_id = var.tgw_id
  }
  # Route for App VPC 2 (inspected E-W) goes to TGW
  route {
    cidr_block         = var.app_vpc_2_cidr
    transit_gateway_id = var.tgw_id
  }

  tags = { Name = "${var.name}-fw-endpoint-rt-${count.index + 1}" }
}
resource "aws_route_table_association" "firewall_endpoint" {
  count          = length(aws_subnet.firewall_endpoint)
  subnet_id      = aws_subnet.firewall_endpoint[count.index].id
  route_table_id = aws_route_table.firewall_endpoint[count.index].id
}


# 3. NAT Gateway Subnets (Public) and NAT GWs (Centralized)
resource "aws_subnet" "nat_gw" {
  count                   = length(var.nat_gw_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.nat_gw_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.name}-nat-gw-subnet-${count.index + 1}" }
}

resource "aws_eip" "nat_gw" {
  count  = length(aws_subnet.nat_gw)
  domain = "vpc"
  tags   = { Name = "${var.name}-nat-gw-eip-${count.index + 1}" }
}

resource "aws_nat_gateway" "main" {
  count         = length(aws_subnet.nat_gw)
  allocation_id = aws_eip.nat_gw[count.index].id
  subnet_id     = aws_subnet.nat_gw[count.index].id
  tags          = { Name = "${var.name}-nat-gw-${count.index + 1}" }
}

# Route Tables for NAT GW Subnets
# Per your request: "Natgw subnet : default route to igw and route to VPC 1 and 2 to endpoint"
resource "aws_route_table" "nat_gw" {
  count  = length(aws_subnet.nat_gw)
  vpc_id = aws_vpc.main.id

  # Egress to Internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # Return traffic for App VPC 1 -> GWLB Endpoint
  route {
    cidr_block           = var.app_vpc_1_cidr
    network_interface_id = local.gwlb_eni_per_az[local.nat_gw_rt_az_map[count.index]]
  }
  # Return traffic for App VPC 2 -> GWLB Endpoint
  route {
    cidr_block           = var.app_vpc_2_cidr
    network_interface_id = local.gwlb_eni_per_az[local.nat_gw_rt_az_map[count.index]]
  }

  tags = { Name = "${var.name}-nat-gw-rt-${count.index + 1}" }
}

resource "aws_route_table_association" "nat_gw" {
  count          = length(aws_subnet.nat_gw)
  subnet_id      = aws_subnet.nat_gw[count.index].id
  route_table_id = aws_route_table.nat_gw[count.index].id
}


# 4. TGW Attachment Subnets (Dedicated for TGW ENI)
resource "aws_subnet" "tgw_attachment" {
  count             = length(var.tgw_attachment_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.tgw_attachment_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "${var.name}-tgw-attach-subnet-${count.index + 1}" }
}

# Dedicated Route Tables for TGW Subnets
# Per your request: "TGW subnets will have a 0.0.0.0/0 route to Endpoints"
resource "aws_route_table" "tgw_attachment" {
  count  = length(aws_subnet.tgw_attachment)
  vpc_id = aws_vpc.main.id

  # Route ALL traffic (0.0.0.0/0, 10.1.0.0/16, 10.2.0.0/16) to the GWLB Endpoint
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = local.gwlb_eni_per_az[local.tgw_rt_az_map[count.index]]
  }

  tags = { Name = "${var.name}-tgw-attach-rt-${count.index + 1}" }
}

resource "aws_route_table_association" "tgw_attachment" {
  count          = length(aws_subnet.tgw_attachment)
  subnet_id      = aws_subnet.tgw_attachment[count.index].id
  route_table_id = aws_route_table.tgw_attachment[count.index].id
}
