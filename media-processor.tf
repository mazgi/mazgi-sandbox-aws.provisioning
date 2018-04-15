# --------------------------------
# S3 bucket

resource "aws_s3_bucket" "media-processor-src" {
  bucket        = "${var.aws_account_name}-media-processor-src"
  tags          = {}
  force_destroy = true
}

# --------------------------------
# IAM user

# IAM user for CircleCI
resource "aws_iam_user" "media-processor-circleci" {
  name          = "media-processor-circleci"
  force_destroy = true
}

# --------------------------------
# IAM group

data "aws_iam_policy_document" "media-processor-s3-admin-group-policy" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "${aws_s3_bucket.media-processor-src.arn}",
    ]
  }
}

resource "aws_iam_policy" "media-processor-s3-admin-group-policy" {
  name   = "media-processor-s3-admin-group-policy"
  policy = "${data.aws_iam_policy_document.media-processor-s3-admin-group-policy.json}"
}

resource "aws_iam_group" "media-processor-s3-admin-group" {
  name = "media-processor-s3-admin-group"
}

resource "aws_iam_group_policy_attachment" "media-processor-s3-admin-group-attachment" {
  group      = "${aws_iam_group.media-processor-s3-admin-group.name}"
  policy_arn = "${aws_iam_policy.media-processor-s3-admin-group-policy.arn}"
}

resource "aws_iam_group_membership" "media-processor-s3-admin-group-membership" {
  name  = "media-processor-s3-admin-group-membership"
  group = "${aws_iam_group.media-processor-s3-admin-group.name}"

  users = [
    "${aws_iam_user.media-processor-circleci.name}",
  ]
}
