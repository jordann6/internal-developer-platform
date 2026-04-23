###############################################################################
# Database Module
# Creates RDS PostgreSQL instance in private subnets with encryption,
# automated backups, and restricted network access.
###############################################################################

###############################################################################
# Subnet Group (places RDS in private subnets only)
###############################################################################

resource "aws_db_subnet_group" "idp" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

###############################################################################
# Security Group (port 5432 from VPC only)
###############################################################################

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL access from within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "No outbound needed for RDS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-rds-sg"
  })
}

###############################################################################
# RDS PostgreSQL Instance
###############################################################################

resource "aws_db_instance" "backstage" {
  identifier = "${var.project_name}-backstage-db"

  engine               = "postgres"
  engine_version       = "16.4"
  instance_class       = var.db_instance_class
  parameter_group_name = "default.postgres16"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  username = var.db_username
  password = var.db_password
  db_name  = var.db_name

  db_subnet_group_name   = aws_db_subnet_group.idp.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  port                   = 5432

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  deletion_protection       = false
  skip_final_snapshot       = true
  final_snapshot_identifier = null

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.kms_key_arn
  performance_insights_retention_period = 7

  tags = merge(var.tags, {
    Name = "${var.project_name}-backstage-db"
  })
}
