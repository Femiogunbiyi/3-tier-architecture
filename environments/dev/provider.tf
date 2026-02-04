terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Local Backend
terraform {
  backend "local" {
    path = "/terraform"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
}
}
