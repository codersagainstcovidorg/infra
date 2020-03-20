locals {
  fctcom  = "findcovidtesting.com"
  fc19torg = "findcovidtesting.org"
}

# Hosted zones
resource "aws_route53_zone" "findcovidtestingcom" {
  name = local.fctcom
}
resource "aws_route53_zone" "findcovid19testingorg" {
  name = local.fc19torg
}

#######################
# findcovidtesting.com
#######################

# cname www to apex domain
resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.findcovidtestingcom.zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "500"
  records = ["${local.fctcom}"]
}

# main site to cloudfront
resource "aws_route53_record" "fctcom-cloudfront" {
  zone_id = aws_route53_zone.findcovidtestingcom.zone_id
  name    = local.fctcom
  type    = "A"

  alias {
    name                   = var.cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2" # this is static
    evaluate_target_health = false
  }
}

#######################
# findcovid19testing.org
#######################

# redirect to main site
resource "aws_route53_record" "fc19torg-fctcom" {
  zone_id = aws_route53_zone.findcovid19testingorg.zone_id
  name    = local.fc19torg
  type    = "A"

  alias {
    name                   = aws_s3_bucket.fc19torg.website_domain
    zone_id                = aws_s3_bucket.fc19torg.hosted_zone_id
    evaluate_target_health = false
  }
}