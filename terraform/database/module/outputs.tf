output "vpc_id" {
  description = "The current VPC for this environment"
  value       = data.aws_vpc.current.id
}

output "private_subnets" {
  description = "The current private subnets for this environment"
  value       = data.aws_subnet_ids.private_subnets.ids
}
