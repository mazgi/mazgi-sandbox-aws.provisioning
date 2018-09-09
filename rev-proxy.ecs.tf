resource "aws_ecs_cluster" "rev-proxy-cluster" {
  name = "rev-proxy-cluster"
}

resource "aws_ecs_task_definition" "rev-proxy-task-rev-proxy" {
  family                   = "rev-proxy-task-rev-proxy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  # see: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html
  cpu                   = 256
  memory                = 512
  container_definitions = "${file("rev-proxy/aws_ecs_task_definition/rev-proxy-task-rev-proxy/container_definitions.json")}"
  execution_role_arn    = "${aws_iam_role.rev-proxy-ecs-execution_role.arn}"
}

resource "aws_ecs_service" "rev-proxy-service-rev-proxy" {
  name            = "rev-proxy-service-rev-proxy"
  task_definition = "${aws_ecs_task_definition.rev-proxy-task-rev-proxy.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  cluster         = "${aws_ecs_cluster.rev-proxy-cluster.arn}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.rev-proxy-service-rev-proxy.arn}"
    container_name   = "rev-proxy"
    container_port   = "80"
  }

  network_configuration {
    subnets = ["${aws_subnet.rev-proxy-subnet-private.*.id}"]

    security_groups = [
      "${aws_security_group.rev-proxy-ec2-allow-http-from-alb.id}",
    ]
  }
}
