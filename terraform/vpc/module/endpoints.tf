resource "aws_security_group" "allow-endpoint" {
  name        = "${var.environment}_rds_endpoint"
  description = "Allow endpoint inbound traffic"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "allow_all" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  source_security_group_id = aws_security_group.allow-endpoint.id

  security_group_id = aws_security_group.allow-endpoint.id
}

resource "aws_vpc_endpoint" "rds" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.rds-data"
  vpc_endpoint_type = "Interface"
  subnet_ids = ["${module.vpc.private_subnets[0]}"]

  security_group_ids = [
    "${aws_security_group.allow-endpoint.id}",
  ]

  private_dns_enabled = true
}
