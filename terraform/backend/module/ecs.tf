resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment}-ecs"
}

locals {
  container_definition = {
    name                   = var.container_name
    networkMode            = var.network_mode
    image                  = "${aws_ecr_repository.backend.repository_url}:${var.image_tag}"
    essential              = var.essential
    readonlyRootFilesystem = var.readonly_root_filesystem
    portMappings           = var.port_mappings
    memory                 = var.container_memory
    cpu                    = var.container_cpu
    environment            = var.container_environment
    logConfiguration       = {
      logDriver = "awslogs"
      options = {
        awslogs-group = aws_cloudwatch_log_group.backend.name
        awslogs-region = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }

  json_data = jsonencode(local.container_definition)
}

resource "aws_ecs_task_definition" "backend" {
  family                = "${var.environment}-backend"
  container_definitions = "[${local.json_data}]"
  requires_compatibilities = var.network_mode == "awsvpc" ? ["FARGATE"] : ["EC2"]
  task_role_arn         = aws_iam_role.ecs_task.arn
  execution_role_arn    = aws_iam_role.ecs_task_execution.arn
  network_mode          = var.network_mode
  memory                 = var.container_memory
  cpu                    = var.container_cpu
}

resource "aws_ecs_service" "backend" {
  depends_on                         = [aws_lb_listener.backend, aws_lb_listener.backend-https]
  name                               = "${var.environment}-backend"
  cluster                            = aws_ecs_cluster.cluster.arn
  task_definition                    = aws_ecs_task_definition.backend.arn
  launch_type                        = var.network_mode == "awsvpc" ? "FARGATE" : "EC2"
  desired_count                      = 1
  platform_version                   = var.network_mode == "awsvpc" ? "LATEST" : null
  enable_ecs_managed_tags            = false
  health_check_grace_period_seconds  = 10
  
  network_configuration {
    security_groups  = [aws_security_group.backend.id]
    subnets          = data.aws_subnet_ids.private_subnets.ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 80
  }
}
