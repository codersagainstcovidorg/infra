variable "default_root_object" {
  description = "Name of default root object e.g index.html"
}

variable "region" {
  description = "aws region"
  default     = "us-east-1"
}

variable "cloudfront_aliases" {
  description = "List of dns aliases"
  type = list(string)
}

variable "use_alias" {
  description = "use alias in CF"
  type = bool
}


variable "price_class" {
  description = "CF Price class"
}

