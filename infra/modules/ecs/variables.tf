variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "container_image" {
  description = "Docker image for the application container, e.g. nginx:latest or a placeholder backend image"
  type        = string
  default     = "nginx:latest"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "task_cpu" {
  description = "Fargate task vCPU units (256 = .25 vCPU)"
  type        = number
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
}

variable "desired_count" {
  type = number
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 2
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "tags" {
  type    = map(string)
  default = {}
}
