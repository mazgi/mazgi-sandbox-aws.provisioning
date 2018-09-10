resource "aws_lb" "rev-proxy-service-rev-proxy" {
  name               = "rev-proxy-service-rev-proxy"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    "${aws_security_group.rev-proxy-alb-allow-http.id}",
  ]

  subnets                    = ["${aws_subnet.rev-proxy-subnet-public.*.id}"]
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "rev-proxy-service-rev-proxy" {
  name        = "rev-proxy-service-rev-proxy"
  port        = "80"
  protocol    = "HTTP"
  vpc_id      = "${aws_vpc.rev-proxy.id}"
  target_type = "ip"

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "rev-proxy-service-rev-proxy-http" {
  load_balancer_arn = "${aws_lb.rev-proxy-service-rev-proxy.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.rev-proxy-service-rev-proxy.arn}"
  }

  depends_on = ["aws_lb_target_group.rev-proxy-service-rev-proxy"]
}
