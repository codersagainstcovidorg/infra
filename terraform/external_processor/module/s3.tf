resource "aws_s3_bucket" "processing" {
  bucket = var.s3_bucket_name
  acl    = "private"

  versioning {
    enabled = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "Terraform"
    Terraform = "true"
  }

  region = var.region

  # TF metadata
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "processing" {
  bucket = aws_s3_bucket.processing.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}