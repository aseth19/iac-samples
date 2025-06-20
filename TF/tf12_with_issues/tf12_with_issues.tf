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
    yor_trace = "35ca2959-5a06-4577-a1dd-be9569907afc"
  }
}