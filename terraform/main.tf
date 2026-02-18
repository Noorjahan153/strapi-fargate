provider "aws" {
  region = var.region
}

resource "aws_ecs_cluster" "main" {
  name = "strapi-cluster"
}

resource "aws_security_group" "sg" {
  name   = "strapi-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 1337
    to_port   = 1337
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_ecs_task_definition" "task" {
  family = "strapi-task"
  cpu    = 512
  memory = 1024

  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name = "strapi"
      image = var.ecr_repo
      essential = true
      portMappings = [
        { containerPort = 1337 }
      ]
    }
  ])
}

resource "aws_ecs_service" "service" {
  name = "strapi-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.sg.id]
    assign_public_ip = true
  }
}
