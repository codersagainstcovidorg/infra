module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.4.0"
  namespace  = var.namespace
  stage      = var.environment
}

module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 2.0"

  name                  = module.label.id
  engine                = "aurora-postgresql"
  engine_version        = "10.7"
  engine_mode           = "serverless"
  replica_scale_enabled = false
  replica_count         = 0
  kms_key_id            = aws_kms_key.database.arn

  backtrack_window = 10 # ignored in serverless

  subnets                         = data.aws_subnet_ids.private_subnets.ids
  vpc_id                          = data.aws_vpc.current.id
  monitoring_interval             = 60
  instance_type                   = "db.r4.large"
  apply_immediately               = true
  skip_final_snapshot             = true
  storage_encrypted               = true

  scaling_configuration = {
    auto_pause               = true
    min_capacity             = 2
    max_capacity             = 384
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  tags = {
    Environment = var.environment
  }
}
