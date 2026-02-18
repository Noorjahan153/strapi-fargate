provider "aws" {
  region = "ap-south-2"
}

################ VPC ################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-2b"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "strapi" {
  name   = "strapi-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
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

################ ECS CLUSTER ################

resource "aws_ecs_cluster" "cluster" {
  name = "strapi-cluster"
}

################ IAM ROLE ################

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

################ ALB ################

resource "aws_lb" "alb" {
  name               = "strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.strapi.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "strapi-tg"
  port     = 1337
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

################ ECS TASK ################

variable "ecr_repo" {}

resource "aws_ecs_task_definition" "task" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "strapi"
    image     = var.ecr_repo
    essential = true

    portMappings = [{
      containerPort = 1337
      hostPort      = 1337
      protocol      = "tcp"
    }]
  }])
}

################ ECS SERVICE ################

resource "aws_ecs_service" "service" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.strapi.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_execution_policy, aws_lb_listener.listener]
}

################ OUTPUT ################

output "strapi_url" {
  value = aws_lb.alb.dns_name
}
