data "aws_iam_policy_document" "rev-proxy-ecs-execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rev-proxy-ecs-execution_role" {
  name               = "rev-proxy-ecs-execution_role"
  assume_role_policy = "${data.aws_iam_policy_document.rev-proxy-ecs-execution_role.json}"
}

resource "aws_iam_policy_attachment" "rev-proxy-ecs-execution_role-AmazonECSTaskExecutionRolePolicy" {
  name       = "rev-proxy-ecs-execution_role-AmazonECSTaskExecutionRolePolicy"
  roles      = ["${aws_iam_role.rev-proxy-ecs-execution_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
