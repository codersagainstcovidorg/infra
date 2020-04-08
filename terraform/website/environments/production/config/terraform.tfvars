environment = "production"
region = "us-east-1"
# Cloudfront bucket name
s3_bucket_name = "cac-website-production-jkq201"
default_root_object = "index.html"
acm_certificate_arn = "arn:aws:acm:us-east-1:656509764755:certificate/f9f458e9-144c-4b5b-919c-56c3624c0baa"

# Set to true and update list below to set an alias
use_alias = true
cloudfront_aliases = ["codersagainstcovid.org"]

# US and Europe edge locations
price_class = "PriceClass_100"
