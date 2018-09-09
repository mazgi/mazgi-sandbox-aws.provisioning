# --------------------------------
# Terraform configuration

terraform {
  required_version = "= 0.11.8"

  backend "s3" {
    bucket = "mazgi-sandbox-aws-terraform"
    key    = "global/tfstate"
    region = "us-east-1"                   # N. Virginia
  }
}

provider "aws" {
  version    = "= 1.14.1"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"             # N. Virginia
}
