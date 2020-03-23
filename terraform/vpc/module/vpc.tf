module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.4.0"
  namespace  = var.namespace
  stage      = var.environment
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = module.label.id
  cidr = var.cidr_block

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true

  public_dedicated_network_acl = true
  public_inbound_acl_rules = concat(
    local.network_acls["default_inbound"],
    local.network_acls["public_inbound"],
  )
  public_outbound_acl_rules = concat(
    local.network_acls["default_outbound"],
    local.network_acls["public_outbound"],
  )

  private_dedicated_network_acl = true

  tags = {
    Environment = var.environment
  }

  public_subnet_tags = {
    Tier = "public"
  }

  private_subnet_tags = {
    Tier = "private"
  }
}
