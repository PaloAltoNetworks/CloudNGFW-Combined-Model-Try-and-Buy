output "vpc_id" {
  description = "The ID of the Security VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "The CIDR block of the Security VPC"
  value       = var.vpc_cidr
}

output "tgw_subnet_ids" {
  description = "List of TGW attachment subnet IDs"
  value       = aws_subnet.tgw_attachment[*].id
}
