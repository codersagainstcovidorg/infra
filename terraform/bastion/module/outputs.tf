output "instance_id" {
  value = module.bastion.id[0]
}

output "bastion_ip" {
  value = module.bastion.public_ip[0]
}

output "az" {
  value = module.bastion.availability_zone[0]
}
