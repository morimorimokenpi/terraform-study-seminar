terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "MyVPC"
    Test = "Terraform"
  }
}

output "vpc_id" {
  value = aws_vpc.example.id
}


resource "aws_ecs_cluster" "example" {
  name = "cluster01"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "example" {
  family = "testtask01"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "nginx:latest"
      memory    = 512
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_iam_role" "ecs_execution" {
  # name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_ecs_service" "example" {
  name                              = "aws_ecs_service_example"
  cluster                           = aws_ecs_cluster.example.id
  task_definition                   = aws_ecs_task_definition.example.arn
  desired_count                     = "1"
  health_check_grace_period_seconds = "60"
  launch_type                       = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.example.id]
    subnets         = [for x in data.aws_subnet.private : x.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "example"
    container_port   = "example"
  }
}

resource "aws_lb_target_group" "example" {
  name                 = "aws_lb_target_group_example"
  vpc_id               = aws_vpc.example.id
  target_type          = "ip"
  port                 = 80
  protocol             = "HTTP"
  deregistration_delay = 60
}

# VPC情報の取得
data "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}
