data "aws_ami" "amazon_linux_2" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
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
