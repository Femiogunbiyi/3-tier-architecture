variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type = string
}

variable "project_name" {
  description = "3 tier architecture"
  type = string
}

variable "vpc_id" {
  description = "VPC ID where the security groups will be created"
  type = string
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to bastion host"
  type = list(string)
  default = [ "0.0.0.0/0" ]
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type = map(string)
  default = {}
}

