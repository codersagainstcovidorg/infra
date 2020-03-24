resource "aws_kms_key" "ssm" {
  description             = "SSM KMS key"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "ssm" {
  name          = "alias/${var.environment}"
  target_key_id = aws_kms_key.ssm.key_id
}

