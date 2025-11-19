variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ca-central-1"
}

variable "availability_zones" {
  description = "List of availability zones to use (must be 2)"
  type        = list(string)
  default     = ["ca-central-1a", "ca-central-1b"]
}

variable "instance_key_name" {
  description = "The EC2 Key Pair name (required for instance deployment)"
  type        = string
}

variable "ec2_instance_type" {
  description = "The EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "firewall_subnet_cidrs_app_1" {
  description = "A list of CIDR blocks for firewall subnets in App VPC 1 (2 AZs)"
  type        = list(string)
  default     = ["10.1.7.0/28", "10.1.8.0/28"]
}

variable "firewall_subnet_cidrs_app_2" {
  description = "A list of CIDR blocks for firewall subnets in App VPC 2 (2 AZs)"
  type        = list(string)
  default     = ["10.2.7.0/28", "10.2.8.0/28"]
}

variable "gwlb_service_name" {
  description = "The VPC Endpoint Service Name for the GWLB (e.g., com.amazonaws.vpce.us-east-1.vpce-svc-xxxxxxxx)"
  type        = string
}
