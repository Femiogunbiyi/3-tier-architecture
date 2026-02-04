variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type = string
  default = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type = string
}

variable "project_name" {
  description = "3 tier architecture"
  type = string
}

variable "availability_zones" {
  description = "List of avaialbilty zones"
  type = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRS for Public Subnets"
  type = list(string)
}

variable "frontend_subnet_cidrs" {
  description = "CIDRS for frontend private Subnets"
  type = list(string)
}

variable "backend_subnet_cidrs" {
  description = "CIDRS for backend private Subnets"
  type = list(string)
}

variable "database_subnet_cidrs" {
  description = "CIDRS for database isolated Subnets"
  type = list(string)
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type = bool
  default = true
}

variable "single_nat_gateway" {
  description = "Single NAT Gateway for all private subnets"
  type = bool
  default = false
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type = map(string)
  default = {}
}

