output "vpc_id" {
  description = "ID of VPC"
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of Public Subnet IDs"
  value = aws_subnet.public[*].id
}

output "frontend_subnet_ids" {
  description = "List of Frontend Subnet IDs"
  value = aws_subnet.frontend[*].id
}

output "backend_subnet_ids" {
  description = "List of Backend Subnet IDs"
  value = aws_subnet.backend[*].id
}

output "database_subnet_ids" {
  description = "List of Database Subnet IDs"
  value = aws_subnet.database[*].id
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT Gateway"
  value = aws_eip.nat[*].public_ip
}

output "internet_gatewa_id"{
  description = "ID of the internet Gateway"
  value = aws_internet_gateway.main.id
}