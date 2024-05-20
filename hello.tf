# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.0"
#     }
#   }
# }

# # Configure the AWS Provider
# provider "aws" {
#   region = "us-east-1"
# }

# # Create a VPC
# resource "aws_vpc" "example" {
#   cidr_block = "10.0.0.0/16"
#   tags = {
#     Name = "MyVPC"
#     Test = "Terraform"
#   }
# }

# output "vpc_id" {
#   value = aws_vpc.example.id
# }


# resource "aws_ecs_cluster" "example" {
#   name = "cluster01"

#   setting {
#     name  = "containerInsights"
#     value = "enabled"
#   }
# }

# resource "aws_ecs_task_definition" "example" {
#   family = "testtask01"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "512"
#   memory                   = "1024"
#   execution_role_arn       = aws_iam_role.ecs_execution.arn
#   container_definitions = jsonencode([
#     {
#       name      = "first"
#       image     = "nginx:latest"
#       memory    = 512
#       portMappings = [
#         {
#           containerPort = 80
#           hostPort      = 80
#         }
#       ]
#     }
#   ])
# }

# resource "aws_iam_role" "ecs_execution" {
#   # name = "ecs_task_execution_role"

#   assume_role_policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Sid": "",
#         "Effect": "Allow",
#         "Principal": {
#           "Service": "ecs-tasks.amazonaws.com"
#         },
#         "Action": "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_ecs_service" "example" {
#   name                              = "aws_ecs_service_example"
#   cluster                           = aws_ecs_cluster.example.id
#   task_definition                   = aws_ecs_task_definition.example.arn
#   desired_count                     = "1"
#   health_check_grace_period_seconds = "60"
#   launch_type                       = "FARGATE"

#   network_configuration {
#     security_groups = [aws_security_group.example.id]
#     subnets         = [for x in data.aws_subnet.private : x.id]
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.example.arn
#     container_name   = "example"
#     container_port   = "example"
#   }
# }

# resource "aws_lb_target_group" "example" {
#   name                 = "aws-lb-target-group-example"
#   vpc_id               = aws_vpc.example.id
#   target_type          = "ip"
#   port                 = 80
#   protocol             = "HTTP"
#   deregistration_delay = 60
# }

# # VPC情報の取得
# data "aws_vpc" "example" {
#   cidr_block = "10.0.0.0/16"
# }



provider "aws" {
  region = "ap-northeast-1"
}

# VPCの作成
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# インターネットゲートウェイの作成
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# ルートテーブルの作成
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

# Subnetの作成
resource "aws_subnet" "my_subnet_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "my_subnet_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
}

# サブネットをルートテーブルに関連付ける
resource "aws_route_table_association" "my_route_table_association_a" {
  subnet_id      = aws_subnet.my_subnet_a.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_route_table_association" "my_route_table_association_b" {
  subnet_id      = aws_subnet.my_subnet_b.id
  route_table_id = aws_route_table.my_route_table.id
}

# IAM Roleの作成
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "my-ecs-task-execution-role"

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
}
# IAM Policyをアタッチ
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECSクラスターの作成
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

# ECSタスク定義の作成
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "my-task-family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "my-container"
      image     = "nginx:latest"
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

# ECSサービスの作成
resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    assign_public_ip = true
    subnets         = [aws_subnet.my_subnet_a.id, aws_subnet.my_subnet_b.id]
    security_groups = [aws_security_group.ecs_service_sg.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "my-container"
    container_port   = 80
  }
}

# セキュリティグループの作成
resource "aws_security_group" "ecs_service_sg" {
  name        = "ecs-service-sg"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ロードバランサー用のセキュリティグループの作成
resource "aws_security_group" "lb_sg" {
  name        = "lb-sg"
  vpc_id      = aws_vpc.my_vpc.id

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
}

# ロードバランサーの作成
resource "aws_lb" "my_lb" {
  name               = "my-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.my_subnet_a.id, aws_subnet.my_subnet_b.id]

  enable_deletion_protection = false
}

# ターゲットグループの作成
resource "aws_lb_target_group" "my_target_group" {
  name        = "my-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id
  target_type = "ip"
}

# リスナーの作成
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}
