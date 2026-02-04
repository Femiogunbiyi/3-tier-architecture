variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type = string
}

variable "project_name" {
  description = "3 tier architecture"
  type = string
}

variable "ami_id" {
  description = "AMI ID"
  type = string
  default = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type = string
  default = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type = string
}

variable "security_group_id" {
  description = "Security group ID for frontend instances"
  type = string
}

variable "subnet_id" {
  description = "Public subnet ID where bastion will be launched"
  type = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type = map(string)
  default = {}
}