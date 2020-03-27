resource "aws_cloudwatch_log_group" "backend" {
  name = "/ecs/${var.environment}/backend"

  tags = {
    Environment = var.environment
  }
}