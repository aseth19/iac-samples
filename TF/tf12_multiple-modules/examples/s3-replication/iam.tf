resource "aws_iam_role" "replication" {
  name = "s3-bucket-replication-${random_pet.this.id}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
  tags = {
    yor_trace = "9a8c7588-fdec-49fc-9efb-74f9faddd813"
  }
}

resource "aws_iam_policy" "replication" {
  name = "s3-bucket-replication-${random_pet.this.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${local.bucket_name}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${local.destination_bucket_name}/*"
    }
  ]
}
POLICY
  tags = {
    yor_trace = "4f78f090-e678-4b2c-adba-7e319b61d909"
  }
}

resource "aws_iam_policy_attachment" "replication" {
  name       = "s3-bucket-replication-${random_pet.this.id}"
  roles      = [aws_iam_role.replication.name]
  policy_arn = aws_iam_policy.replication.arn
}
