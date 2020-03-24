variable "region" {
  description = "aws region"
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment to deploy into"
}

variable "namespace" {
  description = "Organization name or abbreviation"
}
variable "max_capacity" {
  description = "Capacity for the cluster"
  type = number
}
variable "min_capacity" {
  description = "Capacity for the cluster"
  type = number
}
