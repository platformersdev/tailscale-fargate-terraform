data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  name          = "tailscale-vpn"
}
resource "aws_ecs_cluster" "default" {
  name = local.name
}
resource "aws_ecs_service" "default" {
  name            = local.name
  cluster         = aws_ecs_cluster.default.name
  task_definition = aws_ecs_task_definition.default.arn
  launch_type     = "FARGATE"

  desired_count          = 1
  enable_execute_command = true

  network_configuration {
    assign_public_ip = false

    subnets = var.subnets

    security_groups = [aws_security_group.default.id]
  }

  wait_for_steady_state = true
}

data "aws_subnet" "subnet" {
  id = var.subnets[0]
}

resource "aws_security_group" "default" {
  name   = local.name
  vpc_id = data.aws_subnet.subnet.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ecs_task_definition" "default" {
  family = local.name
  container_definitions = jsonencode([
    {
      name      = "tailscale"
      image     = var.image_name
      essential = true
      linuxParameters = {
        initProcessEnabled = true
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.default.name,
          "awslogs-region"        = data.aws_region.current.name,
          "awslogs-stream-prefix" = local.name
        }
      }
      environment = var.container_environment
      command = var.container_command
    }
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  execution_role_arn = aws_iam_role.execution.arn
  task_role_arn      = aws_iam_role.task.arn
}

resource "aws_cloudwatch_log_group" "default" {
  name              = "ecs/${local.name}"
  retention_in_days = 30
}
