# --------------------------------
# S3 bucket

resource "aws_s3_bucket" "media-processor-src" {
  bucket        = "${var.aws_account_name}-media-processor-src"
  tags          = {}
  force_destroy = true
}

resource "aws_lambda_permission" "media-processor-src-allow-invoke-preprocess-function" {
  statement_id  = "media-processor-src-allow-invoke-preprocess-functio"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.media-processor-preprocess-function.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.media-processor-src.arn}"
}

resource "aws_s3_bucket_notification" "media-processor-src-bucket_notification" {
  bucket = "${aws_s3_bucket.media-processor-src.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.media-processor-preprocess-function.arn}"

    events = [
      "s3:ObjectCreated:*",
    ]
  }
}

# --------------------------------
# Lambda function

data "archive_file" "media-processor-preprocess-function-archive" {
  type        = "zip"
  source_dir  = "media-processor-lambda-preprocess-function"
  output_path = "${path.module}/tmp/media-processor-lambda-preprocess-function.zip"
}

resource "aws_lambda_function" "media-processor-preprocess-function" {
  filename         = "${path.module}/tmp/media-processor-lambda-preprocess-function.zip"
  source_code_hash = "${data.archive_file.media-processor-preprocess-function-archive.output_base64sha256}"
  function_name    = "media-processor-preprocess"
  role             = "${aws_iam_role.media-processor-lambda-role.arn}"
  handler          = "media-processor-lambda-preprocess-function.lambda_handler"
  runtime          = "python2.7"

  environment {
    variables = {
      SQS_URL = "${aws_sqs_queue.media-processor-preprocess-queue.id}"
    }
  }
}

# --------------------------------
# SQS queue

resource "aws_sqs_queue" "media-processor-preprocess-queue" {
  name = "media-processor-preprocess-queue"
}

# --------------------------------
# IAM role

resource "aws_iam_role" "media-processor-lambda-role" {
  name = "media-processor-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "media-processor-lambda-role-attachment-s3fullaccess" {
  role       = "${aws_iam_role.media-processor-lambda-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "media-processor-lambda-role-attachment-sqsfullaccess" {
  role       = "${aws_iam_role.media-processor-lambda-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
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

# --------------------------------
# IAM user

# IAM user for CircleCI
resource "aws_iam_user" "media-processor-circleci" {
  name          = "media-processor-circleci"
  force_destroy = true
}
