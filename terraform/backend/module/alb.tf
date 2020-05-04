resource "aws_s3_bucket" "log-bucket" {
  bucket_prefix = "${var.env}-${var.app}-external-alb-logs"
}

data "template_file" "log-bucket-policy" {
  template = "${file("${path.module}/log-bucket-policy.json.tpl")}"

  vars = {
    alb_account_id = "${lookup(var.aws_region_map, "${data.aws_region.current.name}")}"
    s3_arn         = "${aws_s3_bucket.log-bucket.arn}"
    account_id     = "${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_s3_bucket_policy" "attach-policy-to-log-bucket" {
  bucket = "${aws_s3_bucket.log-bucket.id}"
  policy = "${data.template_file.log-bucket-policy.rendered}"
}


# alb
resource "aws_lb" "backend" {
  name                             = "${var.environment}-backend"
  internal                         = false
  load_balancer_type               = "application"
  subnets                          = data.aws_subnet_ids.public_subnets.ids
  security_groups                  = [aws_security_group.lb_sg.id]
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = false
  access_logs {
    bucket  = "${aws_s3_bucket.log-bucket.bucket}"
  }  
  tags = {
    Name = "${var.environment}-backend"
  }
}

resource "aws_lb_target_group" "backend" {
  depends_on  = [aws_lb.backend]
  name        = "${var.environment}-backend"
  target_type = "ip"
  protocol    = "HTTP"
  port        = 80
  vpc_id      = data.aws_vpc.current.id
  health_check {
    path = var.lb_health_check_path
    port = 80
  }
  tags = {
    Name = "${var.environment}-backend-tg"
  }
}

resource "aws_lb_listener" "backend" {
  depends_on        = [aws_lb_target_group.backend]
  load_balancer_arn = aws_lb.backend.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
resource "aws_lb_listener" "backend-https" {
  depends_on        = [aws_lb_target_group.backend]
  load_balancer_arn = aws_lb.backend.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.backend.arn
    type             = "forward"
  }
}



# alb rule http -> https