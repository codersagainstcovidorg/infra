resource "aws_cloudwatch_log_group" "processing" {
  name = "/lambda/${var.environment}/processing"

  tags = {
    Environment = var.environment
  }
}