variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type = string
}

variable "project_name" {
  description = "3 tier architecture"
  type = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group"
  type = list(string)
}

variable "security_group_id" {
  description = "Security group ID for RDS"
  type = string
}

variable "instance_class" {
  description = "RDS instance class"
  type = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type = number
  default = 20
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type = string
  default = "15.5"
}

variable "db_name" {
  description = "Database name"
  type = string
  default = "3 Tier Project"
}

variable "db_username" {
  description = "Database master username"
  type = string
  default = "postgres"
}

variable "db_password" {
  description = "Database master password"
  type = string
  sensitive = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type = bool
  default = false
}

variable "availability_zone" {
  description = "Availability zone for single-AZ deployment"
  type = string
  default = null
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type = number
  default = 7
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type = bool
  default = false
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type = bool
  default = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  type = number
  default = 0
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type = map(string)
  default = {}
}
