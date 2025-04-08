terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "foo" {
  bucket = "my-tf-log-bucket"
  acl = "public-read-write"
}

resource "aws_s3_bucket_versioning" "foo" {
  bucket = aws_s3_bucket.foo.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "foo" {
  bucket = aws_s3_bucket.foo.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
    }
  }
}