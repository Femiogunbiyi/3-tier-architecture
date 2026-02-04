variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type = string
}

variable "project_name" {
  description = "3 tier architecture"
  type = string
}

variable "region" {
  description = "AWS region"
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
  default = "t3.micro"
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

variable "subnets_ids" {
  description = "List of subnet IDs for ASG"
  type = list(string)
}

variable "target_group_arn" {
  description = "Target group ARN for ALB"
  type = string
}

variable "min_size" {
  description = "Minimum number of instances"
  type = number
  default = 2
}

variable "max_size" {
  description = "Maximum number of instances"
  type = number
  default = 4
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type = number
  default = 2
}

variable "docker_image" {
  description = "Full Docker image name"
  type = string
}

variable "docker_username" {
  description = "Docker Hub username"
  type = string
  default = ""
}

variable "docker_password" {
  description = "Docker Hub password or access token"
  type = string
  default = ""
  sensitive = true
}

variable "backend_internal_url" {
  description = "Internal URL for backend service"
  type = string
}

variable "alarm_actions" {
  description = "List of ARNs for alarm actions (e.g SNS topics)"
  type = list(string)
  default = [ ]
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type = map(string)
  default = {}
}