provider "aws" {
  region = var.region
}

################ EXISTING VPC ################

data "aws_vpc" "existing" {
  default = true  # Uses the default VPC in ap-south-2
}

################ SUBNETS ################

data "aws_subnets" "existing" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
}

resource "aws_security_group" "strapi" {
  name   = "strapi-sg-${var.environment}"
  vpc_id = data.aws_vpc.existing.id

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

  tags = {
    Name = "strapi-sg-${var.environment}"
  }
}

################ ECS CLUSTER ################

resource "aws_ecs_cluster" "cluster" {
  name = "strapi-cluster-${var.environment}"
}

################ IAM EXECUTION ROLE ################

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole-${var.environment}"

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

################ CLOUDWATCH LOGS ################

resource "aws_cloudwatch_log_group" "strapi" {
  name              = "/ecs/strapi-${var.environment}"
  retention_in_days = 7
}

################ ECS TASK DEFINITION ################

resource "aws_ecs_task_definition" "task" {
  family                   = "strapi-task-${var.environment}"
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
    }]

    environment = [
      { name = "HOST", value = "0.0.0.0" },
      { name = "PORT", value = "1337" },
      { name = "NODE_ENV", value = "production" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/strapi-${var.environment}"
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

################ ECS SERVICE ################

resource "aws_ecs_service" "service" {
  name            = "strapi-service-${var.environment}"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    # Use the first 2 subnets from the existing VPC
    subnets         = slice(data.aws_subnets.existing.ids, 0, 2)
    security_groups = [aws_security_group.strapi.id]
    assign_public_ip = true
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_execution_policy]
}
