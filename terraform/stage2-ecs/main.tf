locals {
  prefix = "norman-ce9"
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "sctp-ce9-tfstate"
    key    = "norman-ce9-module3-coaching2-stage2-ECS.tfstate" # Replace the value of key to <your suggested name>.tfstat   
    region = "us-east-1"
  }
}

data "terraform_remote_state" "stage1" {
  backend = "s3"
  config = {
    bucket = "sctp-ce9-tfstate"
    key    = "norman-ce9-module3-coaching2-stage1-infra.tfstate" # Replace the value of key to <your suggested name>.tfstat   
    region = "us-east-1"
  }
}


# Security Group
resource "aws_security_group" "ecs" {
  name   = "ecs-fargate-sg"
  vpc_id = data.terraform_remote_state.stage1.outputs.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.prefix}-fargate-cluster"
}

# IAM Role for Fargate
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.prefix}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "my-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "my-app"
      image = "${data.terraform_remote_state.stage1.outputs.ecr_repo_url}:${var.image_tag}"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}


#ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "basic-fargate-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "my-app" # must match container_definitions name
    container_port   = 8080     # must match your containerPort
  }

  depends_on = [aws_lb_listener.http]

  network_configuration {
    subnets          = data.terraform_remote_state.stage1.outputs.public_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }
}
