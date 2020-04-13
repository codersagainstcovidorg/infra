data "aws_caller_identity" "current" {}

data "aws_kms_key" "environment" {
  key_id = "alias/${var.environment}"
}
