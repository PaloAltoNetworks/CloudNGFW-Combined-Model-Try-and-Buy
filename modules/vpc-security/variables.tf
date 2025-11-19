variable "name" {
  description = "The name prefix for the VPC and its resources"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "firewall_endpoint_subnet_cidrs" {
  description = "A list of CIDR blocks for firewall endpoint subnets (2 AZs)"
  type        = list(string)
}

variable "nat_gw_subnet_cidrs" {
  description = "A list of CIDR blocks for NAT Gateway subnets (2 AZs)"
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

variable "app_vpc_1_cidr" {
  description = "The CIDR of Application VPC 1"
  type        = string
}
variable "app_vpc_2_cidr" {
  description = "The CIDR of Application VPC 2"
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
