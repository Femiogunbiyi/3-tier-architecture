# AWS current account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Generate random password for Database
resource "random_password" "db_password" {
  length = 16
  special = true

  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  environment = var.environment
  project_name = var.project_name
  frontend_subnet_cidrs = var.frontend_subnet_cidrs
  availability_zones = var.availability_zones
  backend_subnet_cidrs = var.backend_subnet_cidrs
  public_subnet_cidrs = var.public_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  vpc_cidr = var.vpc_cidr
  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway

  tags = var.tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  environment = var.environment
  project_name = var.project_name
  vpc_id = module.vpc.vpc_cidr
  allowed_ssh_cidrs = [ var.allowed_ssh_cidrs ]

  tags = var.tags
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  environment = var.environment
  project_name = var.project_name
  secrets_arns = ["*"]

  tags = var.tags
}

# RDS Module
module "rds" {
  source = "../../modules/rds"

  environment = var.environment
  project_name = var.project_name
  subnet_ids = module.vpc.database_subnet_ids
  security_group_id = module.security_groups.rds_sg_id
  db_password = random_password.db_password.result
  instance_class = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  engine_version = var.db_engine_version
  db_name = var.db_username
  db_username = var.db_username
  multi_az = var.db_multi_az
  backup_retention_period = var.db_backup_retention_period
  skip_final_snapshot = var.db_skip_final_snapshot

  tags = var.tags
}

# Secrets Manager Module
module "secrets" {
  source = "../../modules/secrets"

  environment = var.environment
  project_name = var.environment
  db_password = random_password.db_password.result
  db_username = var.db_username
  db_host = module.rds.db_address
  db_port = module.rds.db_port
  db_name = var.db_name

  tags = var.tags
}

# Bastion Module
module "bastion" {
  source = "../../modules/bastion"

  environment = var.environment
  project_name = var.project_name
  subnet_id = module.vpc.public_subnet_ids[0]
  key_name = var.ssh_key_name
  iam_instance_profile = module.iam.ec2_instance_profile_name
  security_group_id = module.security_groups.bastion_sg_id
  instance_type = var.bastion_instance_type

  tags = var.tags
}

# Public Application Load Balancer Module (Frontend)
module "alb" {
  source = "../../modules/alb"

  environment = var.environment
  project_name = var.project_name
  security_group_id = module.security_groups.alb_sg_id
  vpc_id = module.vpc.vpc_id
  subnets_ids = module.vpc.public_subnet_ids
  name_prefix = "public-"
  internal = false
  target_group_port = 3000

  tags = var.tags
}

# Internal Application Load Balancer Module (Backend)
module "internal_alb" {
  source = "../../modules/alb"

  environment = var.environment
  project_name = var.project_name
  name_prefix = "internal-"
  internal = true
  security_group_id = module.security_groups.internal_alb_sg_id
  vpc_id = module.vpc.vpc_id
  subnets_ids = module.vpc.frontend_subnet_ids
  target_group_port = 8080

  tags = var.tags
}

# Frontend ASG Module
module "frontend_asg" {
  source = "../../modules/frontend-asg"

  environment = var.environment
  project_name = var.project_name
  region = var.region
  security_group_id = module.security_groups.frontend_sg_id
  key_name = var.ssh_key_name
  subnets_ids = module.vpc.frontend_subnet_ids
  target_group_arn = module.alb.target_group_arn
  iam_instance_profile = module.iam.ec2_instance_profile_name
  instance_type = var.frontend_instance_type
  max_size = var.frontend_max_size
  min_size = var.frontend_min_size
  desired_capacity = var.frontend_desired_capacity

  docker_image = var.frontend_docker_image
  docker_password = var.dockerhub_password
  backend_internal_url = "http://${module.internal_alb.alb_dns_name}"
  docker_username = var.dockerhub_username

  tags = var.tags

  depends_on = [ module.rds, module.alb, module.internal_alb ]
}

# Backend ASG
module "backend_asg" {
  source = "../../modules/backend-asg"

  environment = var.environment
  project_name = var.project_name
  region = var.region
  instance_type = var.backend_instance_type
  key_name = var.ssh_key_name
  iam_instance_profile = module.iam.ec2_instance_profile_name
  security_group_id = module.security_groups.backendend_sg_id
  subnets_ids = module.vpc.backend_subnet_ids
  target_group_arn = [module.internal_alb.target_group_arn]
  max_size = var.backend_max_size
  min_size = var.backend_min_size
  desired_capacity = var.backend_desired_capacity

  docker_image = var.backend_docker_image
  docker_password = var.dockerhub_password
  docker_username = var.dockerhub_username
  backend_internal_url = "http://${module.internal_alb.alb_dns_name}"

  tags = var.tags

  depends_on = [ module.rds, module.secrets ]
}