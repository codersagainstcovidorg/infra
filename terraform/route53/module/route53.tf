

# Hosted zones
resource "aws_route53_zone" "findcovidtestingcom" {
  count = var.environment == "production" ? 1 : 0
  name = local.fctcom
}
resource "aws_route53_zone" "findcovid19testingorg" {
  count = var.environment == "production" ? 1 : 0
  name = local.fc19torg
}

#######################
# findcovidtesting.com
#######################

# cname www to apex domain
resource "aws_route53_record" "www" {
  count = var.environment == "production" ? 1 : 0
  zone_id = aws_route53_zone.findcovidtestingcom[0].zone_id
  name    = "www"
  type    = "CNAME"
  ttl     = "500"
  records = ["${local.fctcom}"]
}

# main site to cloudfront
resource "aws_route53_record" "fctcom-cloudfront" {
  count = var.environment == "production" ? 1 : 0
  zone_id = aws_route53_zone.findcovidtestingcom[0].zone_id
  name    = local.fctcom
  type    = "A"

  alias {
    name                   = var.cloudfront_domain
    zone_id                = "Z2FDTNDATAQYW2" # this is static
    evaluate_target_health = false
  }
}

# Had to do it this way because resources were already created and changing module logic would cause downtime
resource "aws_route53_record" "fctcom-cloudfront-staging" {
  count = var.environment == "staging" ? 1 : 0
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = local.fctcom_staging
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

# This is redirected from Google Domains so this is not needed until domain is transferred 
# cname www to apex domain
# resource "aws_route53_record" "www-fc19torg" {
#   zone_id = aws_route53_zone.findcovid19testingorg.zone_id
#   name    = "www"
#   type    = "CNAME"
#   ttl     = "500"
#   records = ["${local.fc19torg}"]
# }

# redirect to main site
# resource "aws_route53_record" "fc19torg-fctcom" {
#   zone_id = aws_route53_zone.findcovid19testingorg.zone_id
#   name    = local.fc19torg
#   type    = "A"

#   alias {
#     name                   = aws_s3_bucket.fc19torg.website_domain
#     zone_id                = aws_s3_bucket.fc19torg.hosted_zone_id
#     evaluate_target_health = false
#   }
# }