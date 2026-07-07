variable "project_name" {
  type    = string
  default = "hotel-bookings"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["ap-south-1a", "ap-south-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.10.10.0/24", "10.10.11.0/24"]
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
  default = 256
}

variable "ecs_task_memory" {
  type    = number
  default = 512
}

variable "ecs_desired_count" {
  type    = number
  default = 1
}

variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
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
  default     = "changeme-dev-only"
}

variable "db_backup_retention_days" {
  type    = number
  default = 3 # dev: short retention
}

variable "db_deletion_protection" {
  type    = bool
  default = false # dev: allow easy teardown
}

variable "ci_mode" {
  description = "When true, skips AWS credential/account validation so `terraform plan` can run without a real AWS account (used by the GitHub Actions workflow)"
  type        = bool
  default     = false
}
