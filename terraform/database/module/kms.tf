resource "aws_kms_key" "database" {
  description             = "Database KMS key"
  deletion_window_in_days = 7
}
