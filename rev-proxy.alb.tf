resource "aws_lb" "rev-proxy-service-rev-proxy" {
  name               = "rev-proxy-service-rev-proxy"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    "${aws_security_group.rev-proxy-default.id}",
    "${aws_security_group.rev-proxy-allow-http.id}",
  ]

  subnets                    = ["${aws_subnet.rev-proxy-subnet-public.*.id}"]
  enable_deletion_protection = true
}

resource "aws_lb_target_group" "rev-proxy-service-rev-proxy" {
  name        = "rev-proxy-service-rev-proxy"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.rev-proxy.id}"
  target_type = "ip"
}

resource "aws_lb_listener" "rev-proxy-service-rev-proxy-http" {
  load_balancer_arn = "${aws_lb.rev-proxy-service-rev-proxy.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.rev-proxy-service-rev-proxy.arn}"
  }
}