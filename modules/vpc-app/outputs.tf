output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR of the VPC"
  value       = var.vpc_cidr
}

output "private_route_table_ids" {
  description = "List of private route table IDs for routing"
  value       = module.vpc.private_route_table_ids
}

output "firewall_subnet_ids" {
  description = "List of firewall subnet IDs"
  value       = aws_subnet.firewall[*].id
}

output "tgw_subnet_ids" {
  description = "List of TGW attachment subnet IDs"
  value       = aws_subnet.tgw_attachment[*].id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.application.dns_name
}
