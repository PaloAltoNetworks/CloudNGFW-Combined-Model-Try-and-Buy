variable "name" {
  description = "The name prefix for the VPC and its resources"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for public subnets (2 AZs)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks for private subnets (2 AZs)"
  type        = list(string)
}

variable "firewall_subnet_cidrs" {
  description = "A list of CIDR blocks for dedicated firewall subnets (2 AZs)"
  type        = list(string)
}

variable "tgw_attachment_subnet_cidrs" {
  description = "A list of CIDR blocks for TGW attachment subnets (2 AZs)"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
}

variable "instance_key_name" {
  description = "The EC2 Key Pair name"
  type        = string
}

variable "ec2_instance_type" {
  description = "The EC2 instance type"
  type        = string
}

variable "ec2_tags" {
  description = "Tags for the EC2 instances"
  type        = map(string)
}

variable "security_vpc_cidr" {
  description = "The CIDR of the Security VPC"
  type        = string
}

variable "other_app_vpc_cidr" {
  description = "The CIDR of the *other* Application VPC"
  type        = string
}

variable "tgw_id" {
  description = "The ID of the Transit Gateway created in the root module"
  type        = string
}

variable "gwlb_service_name" {
  description = "The VPC Endpoint Service Name for the GWLB"
  type        = string
}
