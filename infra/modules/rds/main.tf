locals {
  name = "${var.project_name}-${var.environment}"
  port = var.engine == "postgres" ? 5432 : 3306
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${local.name}-db-subnet-group"
  })
}

# RDS security group: only reachable from the ECS task security group(s).
# No ingress from 0.0.0.0/0 anywhere in this resource.
resource "aws_security_group" "rds" {
  name        = "${local.name}-rds-sg"
  description = "Allow DB access only from ECS tasks"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${local.name}-rds-sg"
  })
}

resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  for_each                 = toset(var.allowed_security_group_ids)
  type                     = "ingress"
  from_port                = local.port
  to_port                  = local.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = each.value
  description               = "Allow DB traffic from ECS task security group"
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
}

resource "aws_db_instance" "this" {
  identifier     = "${local.name}-db"
  engine         = var.engine == "postgres" ? "postgres" : "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = local.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:30-mon:05:30"

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.name}-final-snapshot"

  tags = merge(var.tags, {
    Name = "${local.name}-db"
  })
}
