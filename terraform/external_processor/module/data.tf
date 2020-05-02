data "aws_caller_identity" "current" {}

data "aws_kms_key" "environment" {
  key_id = "alias/${var.environment}"
}

data "aws_vpc" "current" {
  tags = {
    Environment = var.environment
  }
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = data.aws_vpc.current.id
  tags = {
    Tier = "private"
  }
}