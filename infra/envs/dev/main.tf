terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Separate state per environment. Bucket/table are placeholders -
  # replace with real backend resources before first init, or leave
  # local state for evaluation purposes.
  backend "s3" {
    bucket         = "REPLACE_ME-terraform-state-dev"
    key            = "hotel-bookings/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "REPLACE_ME-terraform-locks-dev"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  # ci_mode lets `terraform plan` run in CI with no real AWS account
  # (dummy credentials + no API calls to validate them). Leave false
  # for any real apply.
  skip_credentials_validation = var.ci_mode
  skip_requesting_account_id  = var.ci_mode
  skip_metadata_api_check     = var.ci_mode

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  azs                   = var.azs
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  single_nat_gateway    = true # dev: one shared NAT to save cost
  tags                  = local.common_tags
}

module "ecs" {
  source = "../../modules/ecs"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  container_image = var.container_image
  container_port  = var.container_port

  task_cpu      = var.ecs_task_cpu
  task_memory   = var.ecs_task_memory
  desired_count = var.ecs_desired_count
  min_capacity  = 1
  max_capacity  = 2

  tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  project_name = var.project_name
  environment  = var.environment

  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  allowed_security_group_ids = [module.ecs.ecs_task_security_group_id]

  engine         = var.db_engine
  instance_class = var.db_instance_class

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  multi_az                 = false # dev: single-AZ, cheaper
  backup_retention_period  = var.db_backup_retention_days
  deletion_protection      = var.db_deletion_protection
  skip_final_snapshot      = true # dev: ok to skip on teardown

  tags = local.common_tags
}
