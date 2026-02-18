variable "ecr_repo" {
  description = "Full ECR repository URI including image tag"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = var.ecr_repo
      essential = true

      portMappings = [
        { containerPort = 1337 }
      ]
    }
  ])
}
