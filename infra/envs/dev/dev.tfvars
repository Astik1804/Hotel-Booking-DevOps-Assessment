project_name = "hotel-bookings"
environment  = "dev"
aws_region   = "ap-south-1"

vpc_cidr             = "10.10.0.0/16"
azs                  = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.10.0.0/24", "10.10.1.0/24"]
private_subnet_cidrs = ["10.10.10.0/24", "10.10.11.0/24"]

container_image = "nginx:latest"
container_port   = 80

ecs_task_cpu      = 256
ecs_task_memory   = 512
ecs_desired_count = 1

db_engine          = "postgres"
db_instance_class  = "db.t4g.micro"
db_name            = "hotel_bookings"
db_username        = "app_admin"

# db_password intentionally omitted - supply via TF_VAR_db_password
# or a secrets manager at apply time. Do not put real passwords in tfvars.

db_backup_retention_days = 3
db_deletion_protection   = false
