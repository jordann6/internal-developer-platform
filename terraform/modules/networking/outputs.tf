output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.idp.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.idp.cidr_block
}

output "availability_zones" {
  description = "Availability zones used"
  value       = [for s in aws_subnet.public : s.availability_zone]
}
