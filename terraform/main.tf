terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "realchat-prod-f5ae5800"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─────────────────────────────────────────────
# ECR Repository (Phase 3 — image storage)
# ─────────────────────────────────────────────
resource "aws_ecr_repository" "app_repo" {
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-ecr"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecr_lifecycle_policy" "app_repo_policy" {
  repository = aws_ecr_repository.app_repo.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

# ─────────────────────────────────────────────
# ECS Cluster (Phase 3)
# ─────────────────────────────────────────────
resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ─────────────────────────────────────────────
# IAM — ECS Task Execution Role
# ─────────────────────────────────────────────
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ─────────────────────────────────────────────
# CloudWatch Log Group
# ─────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ecs/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# ─────────────────────────────────────────────
# ECS Task Definition (Phase 3)
# ─────────────────────────────────────────────
resource "aws_ecs_task_definition" "app_task" {
  family                   = "${var.project_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = var.project_name
    image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = var.app_port
      protocol      = "tcp"
    }]

    environment = [
      { name = "NODE_ENV",       value = var.environment },
      { name = "PORT",           value = tostring(var.app_port) },
      { name = "MONGO_URI",      value = var.mongo_uri },
      { name = "JWT_SECRET_KEY", value = var.jwt_secret_key }
    ]

    healthCheck = {
      command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:${var.app_port}/api/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app_logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name        = "${var.project_name}-task"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ─────────────────────────────────────────────
# Networking — VPC / Subnet / Security Group
# ─────────────────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP inbound traffic to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  description = "Allow inbound traffic from ALB to ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ecs-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ─────────────────────────────────────────────
# Application Load Balancer
# ─────────────────────────────────────────────
resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${var.project_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 30
    interval            = 40
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ─────────────────────────────────────────────
# ECS Fargate Service (Phase 3)
# ─────────────────────────────────────────────
resource "aws_ecs_service" "app_service" {
  name            = "${var.project_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = var.project_name
    container_port   = var.app_port
  }

  # Force new deployment when image tag changes
  force_new_deployment = true
  depends_on           = [aws_lb_listener.app_listener]

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name        = "${var.project_name}-service"
    Environment = var.environment
    Project     = var.project_name
  }
}
