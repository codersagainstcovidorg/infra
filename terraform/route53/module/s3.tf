# allows redirect
resource "aws_s3_bucket" "fc19torg" {
  bucket = local.fc19torg
  acl    = "public-read"

  website {

    redirect_all_requests_to = "https://${local.fctcom}"
  }
}
