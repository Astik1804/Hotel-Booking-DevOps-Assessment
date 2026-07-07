project_name = "hotel-bookings"
environment  = "prod"
aws_region   = "ap-south-1"

vpc_cidr             = "10.20.0.0/16"
azs                  = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]

container_image = "nginx:latest"
container_port   = 80

ecs_task_cpu      = 1024
ecs_task_memory   = 2048
ecs_desired_count = 2

db_engine         = "postgres"
db_instance_class = "db.r6g.large"
db_name           = "hotel_bookings"
db_username       = "app_admin"

# db_password intentionally omitted - must be supplied via TF_VAR_db_password
# or a secrets manager at apply time. Never commit a real prod password.

db_backup_retention_days = 30
db_deletion_protection   = true
