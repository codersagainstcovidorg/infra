data "aws_caller_identity" "current" {}

data "aws_vpc" "current" {
  tags = {
    Environment = var.environment
  }
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = data.aws_vpc.current.id
  tags = {
    Tier = "public"
  }
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = data.aws_vpc.current.id
  tags = {
    Tier = "private"
  }
}

data "aws_route53_zone" "selected" {
  name         = "findcovidtesting.com."
  private_zone = false
}

