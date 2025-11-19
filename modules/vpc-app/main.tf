########################################
# modules/vpc-app/main.tf
# Purpose: App VPC for centralized GWLB inspection + TGW egress
########################################

#############################
# 1. VPC (terraform-aws-modules/vpc)
#############################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs

  # Disable NAT (we use TGW for egress)
  enable_nat_gateway     = false
  single_nat_gateway     = false
  one_nat_gateway_per_az = false

  create_igw = false
  enable_vpn_gateway = false
  map_public_ip_on_launch = true

  tags = { Environment = "App" }
}

#############################
# 2. Internet Gateway
#############################
resource "aws_internet_gateway" "this" {
  vpc_id = module.vpc.vpc_id
  tags = { Name = "${var.name}-igw" }
}

#############################
# 3. Subnets
#############################
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${count.index + 1}" }
}

resource "aws_subnet" "firewall" {
  count             = length(var.firewall_subnet_cidrs)
  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.firewall_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = { Name = "${var.name}-fw-${count.index + 1}" }
}

resource "aws_subnet" "tgw_attachment" {
  count             = length(var.tgw_attachment_subnet_cidrs)
  vpc_id            = module.vpc.vpc_id
  cidr_block        = var.tgw_attachment_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = { Name = "${var.name}-tgw-attach-${count.index + 1}" }
}

#############################
# 4. GWLB Endpoints (1 per AZ)
#############################
resource "aws_vpc_endpoint" "gwlb" {
  count             = length(var.firewall_subnet_cidrs)
  vpc_id            = module.vpc.vpc_id
  service_name      = var.gwlb_service_name
  vpc_endpoint_type = "GatewayLoadBalancer"
  subnet_ids        = [aws_subnet.firewall[count.index].id]
  tags              = { Name = "${var.name}-gwlb-endpoint-${count.index + 1}" }
}

#############################
# 5. Local maps
#############################
locals {
  # Map AZ -> GWLB ENI
  gwlb_eni_per_az = {
    for i, ep in aws_vpc_endpoint.gwlb :
    aws_subnet.firewall[i].availability_zone => one(ep.network_interface_ids)
  }

  public_rt_az_map = {
    for i, subnet in aws_subnet.public :
    i => subnet.availability_zone
  }
}

#############################
# 6. Firewall route tables (0.0.0.0/0 -> IGW)
#############################
resource "aws_route_table" "firewall" {
  count  = length(aws_subnet.firewall)
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.name}-fw-rt-${count.index + 1}"
    Role = "Firewall_Internet"
  }
}

resource "aws_route_table_association" "firewall" {
  count          = length(aws_subnet.firewall)
  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall[count.index].id
}

#############################
# 7. Public subnet route tables (0.0.0.0/0 -> GWLB)
#############################
resource "aws_route_table" "public" {
  count  = length(aws_subnet.public)
  vpc_id = module.vpc.vpc_id

  depends_on = [aws_vpc_endpoint.gwlb]

  route {
    cidr_block          = "0.0.0.0/0"
    network_interface_id = local.gwlb_eni_per_az[local.public_rt_az_map[count.index]]
  }

  tags = { Name = "${var.name}-public-gwlb-rt-${count.index + 1}" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

#############################
# 8. IGW Route Table + Edge Association
#############################
resource "aws_route_table" "igw_rt" {
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "${var.name}-igw-rt"
    Role = "IGW_Edge"
  }
}

# Add routes for each public subnet CIDR -> GWLB ENI
resource "aws_route" "igw_to_public_subnets" {
  count                  = length(aws_subnet.public)
  route_table_id         = aws_route_table.igw_rt.id
  destination_cidr_block = var.public_subnet_cidrs[count.index]
  network_interface_id   = local.gwlb_eni_per_az[local.public_rt_az_map[count.index]]
  depends_on             = [aws_vpc_endpoint.gwlb]
}

# Edge association: attach this route table to IGW
resource "aws_route_table_association" "igw_edge_assoc" {
  gateway_id     = aws_internet_gateway.this.id
  route_table_id = aws_route_table.igw_rt.id
}

#############################
# 9. Private subnets default route to TGW
#############################
resource "aws_route" "private_default_to_tgw" {
  count                  = length(module.vpc.private_route_table_ids)
  route_table_id         = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw_id
}

#############################
# 10. ALB (public subnets)
#############################
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Allow inbound HTTP/S"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "application" {
  depends_on = [aws_internet_gateway.this, aws_vpc_endpoint.gwlb]
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "app" {
  name     = "${var.name}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

#############################
# 11. EC2 App Servers (private subnets)
#############################
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2-sg"
  description = "Allow inbound from ALB and SSH"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# ICMP (ping) from anywhere
ingress {
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  count           = length(module.vpc.private_subnets)
  ami             = data.aws_ssm_parameter.al2023_ami.value
  instance_type   = var.ec2_instance_type
  key_name        = var.instance_key_name
  subnet_id       = module.vpc.private_subnets[count.index]
  security_groups = [aws_security_group.ec2.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "<html><h1>Hello from $(hostname -f) in ${var.name}</h1></html>" > /var/www/html/index.html
              EOF

  tags = merge(var.ec2_tags, { Name = "${var.name}-app-${count.index + 1}" })
}

resource "aws_lb_target_group_attachment" "app" {
  count            = length(module.vpc.private_subnets)
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app_server[count.index].id
  port             = 80
}

