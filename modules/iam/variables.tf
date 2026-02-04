variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type = string
}

variable "project_name" {
  description = "3 tier architecture"
  type = string
}

variable "secrets_arns" {
  description = "List of Secrets Manager ARNs that EC2 instances can access"
  type = list(string)
  default = [ "*" ]
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type = map(string)
  default = {}
}