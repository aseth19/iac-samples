terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "foo" {
  bucket = "my-tf-log-bucket"
  acl    = "public-read-write"
  tags = {
    Env       = "prod"
    yor_trace = "6f11c8b6-843a-49e7-b6dc-be7d4d124586"
  }
}