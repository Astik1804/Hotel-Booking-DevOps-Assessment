variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to reach RDS on the DB port (ECS tasks SG)"
  type        = list(string)
}

variable "engine" {
  description = "postgres or mysql"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  type    = string
  default = "16.4"
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "max_allocated_storage" {
  description = "Upper bound for storage autoscaling"
  type        = number
  default     = 100
}

variable "db_name" {
  type    = string
  default = "app"
}

variable "db_username" {
  type      = string
  default   = "app_admin"
  sensitive = true
}

variable "db_password" {
  description = "Master password. In real usage this should come from a secrets manager / SSM parameter, not a plain tfvars value."
  type        = string
  sensitive   = true
}

variable "multi_az" {
  type    = bool
  default = false
}

variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
}

variable "deletion_protection" {
  type = bool
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot on destroy (true only makes sense for dev)"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
