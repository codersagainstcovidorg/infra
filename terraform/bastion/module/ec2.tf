module "label" {
  source     = "git::https://github.com/cloudposse/terraform-terraform-label.git?ref=0.4.0"
  namespace  = var.namespace
  stage      = var.environment
  name       = "bastion"
}

module instance_profile_role {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 2.7.0"

  role_name               = module.label.id
  create_role             = true
  create_instance_profile = true
  role_requires_mfa       = false

  trusted_role_services   = ["ec2.amazonaws.com"]
  custom_role_policy_arns = ["arn:aws:iam::aws:policy/EC2InstanceConnect"]
}

module "bastion_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.1.0"

  name   = module.label.id
  vpc_id = data.aws_vpc.current.id

  # Allow all incoming SSH traffic
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]

  # Allow all outgoing HTTP and HTTPS traffic, as well as communication to db
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["http-80-tcp", "https-443-tcp", "postgresql-tcp"]
}

module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.12.0"

  ami                         = data.aws_ami.ubuntu.id
  name                        = module.label.id
  associate_public_ip_address = true
  instance_type               = "t2.small"
  vpc_security_group_ids      = [module.bastion_security_group.this_security_group_id]
  subnet_ids                  = data.aws_subnet_ids.public_subnets.ids
  iam_instance_profile        = module.instance_profile_role.this_iam_instance_profile_name

  # Install dependencies
  user_data = <<USER_DATA
#!/bin/bash
sudo apt-get update
sudo apt-get -y install ec2-instance-connect
  USER_DATA
}
