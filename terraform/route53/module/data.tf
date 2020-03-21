data "aws_caller_identity" "current" {}
data "aws_route53_zone" "selected" {
  name         = "${local.fctcom}."
  private_zone = false
}