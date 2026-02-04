variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type = string
}

variable "project_name" {
  description = "3 tier architecture"
  type = string
}

variable "name_prefix" {
  description = "Prefix for the ALB name (e.g, 'public-' or 'private-')"
  type = string
  default = ""
}

variable "internal" {
  description = "Whether the ALB is internal"
  type = bool
  default = false
}

variable "vpc_id" {
  description = "VPC ID"
  type = string
}

variable "target_group_port" {
  description = "Port for the target group"
  type = number
  default = 3000
}

variable "subnets_ids" {
  description = "List of public subnets IDs for ALB"
  type = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ALB"
  type = string
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type = bool
  default = false
}

variable "certificate_arn" {
  description = "ACM certficate ARN for HTTPS listener"
  type = string
  default = ""
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type = map(string)
  default = {}
}