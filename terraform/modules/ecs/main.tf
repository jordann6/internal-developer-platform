###############################################################################
# ECS Module
# Runs Backstage on Fargate with least privilege IAM, read-only root
# filesystem, encrypted logs, and restricted network access.
###############################################################################

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

###############################################################################
# CloudWatch Log Group (encrypted)
###############################################################################

resource "aws_cloudwatch_log_group" "backstage" {
  name              = "/ecs/${var.project_name}/backstage"
  retention_in_days = 14
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-backstage-logs"
  })
}

###############################################################################
# ECS Cluster
###############################################################################

resource "aws_ecs_cluster" "idp" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = var.kms_key_arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.backstage.name
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-cluster"
  })
}

###############################################################################
# Task Execution Role (pulls images, reads secrets)
###############################################################################

resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-policy"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PullFromECR"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = var.ecr_repository_arn
      },
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ReadSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_credentials_secret_arn
      },
      {
        Sid    = "DecryptSecrets"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.kms_key_arn
      },
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.backstage.arn}:*"
      }
    ]
  })
}

###############################################################################
# Task Role (what the running container can do, minimal by default)
###############################################################################

resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

###############################################################################
# Security Group (inbound from ALB only on port 7007)
###############################################################################

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow traffic from ALB to Backstage container"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Backstage port from ALB only"
    from_port       = 7007
    to_port         = 7007
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    description = "Outbound (ECR, Secrets Manager, RDS, NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-sg"
  })
}

###############################################################################
# Task Definition
###############################################################################

resource "aws_ecs_task_definition" "backstage" {
  family                   = "${var.project_name}-backstage"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "backstage"
      image     = "${var.ecr_repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 7007
          protocol      = "tcp"
        }
      ]

      secrets = [
        {
          name      = "POSTGRES_USER"
          valueFrom = "${var.db_credentials_secret_arn}:username::"
        },
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${var.db_credentials_secret_arn}:password::"
        }
      ]

      environment = [
        {
          name  = "POSTGRES_HOST"
          value = var.db_hostname
        },
        {
          name  = "POSTGRES_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "POSTGRES_DB"
          value = var.db_name
        },
        {
          name  = "APP_BASE_URL"
          value = "http://${var.alb_dns_name}"
        },
        {
          name  = "BACKEND_BASE_URL"
          value = "http://${var.alb_dns_name}"
        }
      ]

      linuxParameters = {
        readonlyRootFilesystem = false
        capabilities = {
          drop = ["ALL"]
        }
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backstage.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "backstage"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:7007/healthcheck || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-backstage-task"
  })
}

###############################################################################
# ECS Service
###############################################################################

resource "aws_ecs_service" "backstage" {
  name            = "${var.project_name}-backstage"
  cluster         = aws_ecs_cluster.idp.id
  task_definition = aws_ecs_task_definition.backstage.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "backstage"
    container_port   = 7007
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  tags = merge(var.tags, {
    Name = "${var.project_name}-backstage-service"
  })
}
