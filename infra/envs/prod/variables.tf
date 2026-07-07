variable "project_name" {
  type    = string
  default = "hotel-bookings"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
}

variable "container_image" {
  type    = string
  default = "nginx:latest"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "ecs_task_cpu" {
  type    = number
  default = 1024
}

variable "ecs_task_memory" {
  type    = number
  default = 2048
}

variable "ecs_desired_count" {
  type    = number
  default = 2
}

variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_instance_class" {
  type    = string
  default = "db.r6g.large"
}

variable "db_name" {
  type    = string
  default = "hotel_bookings"
}

variable "db_username" {
  type    = string
  default = "app_admin"
}

variable "db_password" {
  description = "Master DB password - pass via TF_VAR_db_password or a secrets backend, never commit a real value"
  type        = string
  sensitive   = true
  default     = "" # intentionally blank; must be supplied at apply time in prod
}

variable "db_backup_retention_days" {
  type    = number
  default = 30 # prod: long retention
}

variable "db_deletion_protection" {
  type    = bool
  default = true # prod: protect against accidental destroy
}

variable "ci_mode" {
  description = "When true, skips AWS credential/account validation so `terraform plan` can run without a real AWS account (used by the GitHub Actions workflow)"
  type        = bool
  default     = false
}
