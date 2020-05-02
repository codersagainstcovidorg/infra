

variable "region" {
  description = "aws region"
  default     = "us-east-1"
}


variable "s3_bucket_name" {
  description = "S3 bucket name"
}
variable "environment" {
  description = "Environment to deploy into"
}

variable "security_group_ids" {
  description = "SG id to allow endpoint access"
}




