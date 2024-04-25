terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "my-tf-log-bucket"
  acl    = "log-delivery-write"
  tags = {
    yor_trace = "cbdf8c76-972b-4825-b9f7-0193bf79f581"
  }
}
resource "aws_s3_bucket" "foo" {
  // 23. AWS S3 buckets are accessible to public (high)
  // $.resource[*].aws_s3_bucket exists and ($.resource[*].aws_s3_bucket.*[*].*.acl anyEqual public-read-write or $.resource[*].aws_s3_bucket.*[*].*.acl anyEqual public-read)
  acl = "public-read-write"

  bucket = "foo_name"
  // 24. AWS S3 Object Versioning is disabled (medium)
  // $.resource[*].aws_s3_bucket exists and ($.resource[*].aws_s3_bucket.*[*].*.versioning[*].enabled does not exist or $.resource[*].aws_s3_bucket.*[*].*.versioning[*].enabled anyFalse)
  versioning {
    enabled = false
  }
  // 1. AWS S3 CloudTrail buckets for which access logging is disabled ()
  // $.resource[*].aws_cloudtrail[*].*[*].enable_logging anyFalse
  // UPDATED Policy: "AWS Access logging not enabled on S3 buckets"
  // $.resource.aws_s3_bucket exists and ($.resource.aws_s3_bucket[*].logging anyNull or $.resource.aws_s3_bucket[*].logging[*].target_bucket !exists or $.resource.aws_s3_bucket[*].logging[*].target_bucket anyNull)
  logging {
    target_bucket = aws_s3_bucket.log_bucket.id
    target_prefix = "log/"
  }
  tags = {
    yor_trace = "b7c8d234-d634-43cd-b9d3-9946e630786b"
  }
}

resource "aws_cloudtrail" "foo_cloudtrail" {
  // 2. AWS CloudTrail bucket is publicly accessible (high)
  // $.resource[*].aws_cloudtrail exists and $.resource[*].aws_cloudtrail[*].*[*].s3_bucket_name equals $.resource[*].aws_s3_bucket_public_access_block[*].*[*].bucket and  ($.resource[*].aws_s3_bucket_public_access_block[*].*[*].block_public_acls isFalse or  $.resource[*].aws_s3_bucket_public_access_block[*].*[*].block_public_policy isFalse)
  name           = "tf-trail-foobar"
  s3_bucket_name = aws_s3_bucket.foo.id
  // 3. AWS CloudTrail logs are not encrypted using Customer Master Keys (CMKs)
  // $.resource[*].aws_cloudtrail exists and ($.resource[*].aws_cloudtrail[*].*[*].kms_key_id anyNull or $.resource[*].aws_cloudtrail[*].*[*].kms_key_id anyEmpty)
  // #REMOVED TO MAKE RULE MATCH# kms_key_id = "arn:aws:kms:us-west-2:111122223333:key"
  s3_key_prefix                 = "prefix"
  include_global_service_events = false
  enable_logging                = false
  tags = {
    yor_trace = "2f1b18cb-5b2d-4afc-bb32-ec1a3c322854"
  }
}
resource "aws_s3_bucket_public_access_block" "example" {
  // 2+. AWS CloudTrail bucket is publicly accessible (high)
  bucket              = aws_s3_bucket.foo.id
  block_public_acls   = false
  block_public_policy = true
}

// ??? [Rule Not Matching] 30. AWS VPC allows unauthorized peering
// $.resource[*].aws_vpc_peering_connection[*].*[*].peer_vpc_id does not equal $.resource[*].aws_vpc_peering_connection[*].*[*].vpc_id
resource "aws_vpc_peering_connection" "foo" {
  peer_owner_id = "123"
  peer_vpc_id   = aws_vpc.bar_vpc.id
  vpc_id        = aws_vpc.foo_vpc.id
  tags = {
    yor_trace = "7e8be577-d994-485c-9f24-83e1e35f084b"
  }
}
resource "aws_vpc" "foo_vpc" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name      = "foo-vpc-example"
    yor_trace = "ad12945f-0585-49ea-b434-a51dcb924211"
  }
}
resource "aws_vpc" "bar_vpc" {
  cidr_block = "172.17.0.0/16"
  tags = {
    Name      = "bar-vpc-example"
    yor_trace = "c12b51c6-547a-4b34-9d06-d2cfb0f7e6a9"
  }
}

resource "aws_security_group" "allow_tcp" {
  name        = "allow_tcp"
  description = "Allow TCP inbound traffic"
  vpc_id      = aws_vpc.foo_vpc.id
  // 6. AWS Security Groups allow internet traffic to SSH port (22)
  // $.resource[*].aws_security_group exists and ($.resource[*].aws_security_group[*].*[*].ingress[?( @.protocol == 'tcp' && @.from_port<23 && @.to_port>21 )].cidr_blocks[*] contains 0.0.0.0/0 or $.resource[*].aws_security_group[*].*[*].ingress[?( @.protocol == 'tcp' && @.from_port<23 && @.to_port>21 )].ipv6_cidr_blocks[*] contains ::/0)
  ingress {
    description = "TCP from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  // 31. AWS security group allows egress traffic to blocked ports - 21,22,135,137-139,445,69
  // $.resource[*].aws_security_group exists and $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == 'tcp' && @.from_port == '22' && @.to_port == '22')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == 'tcp' && @.from_port == '22' && @.to_port == '22')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == 'tcp' && @.from_port == '21' && @.to_port == '21')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == 'tcp' && @.from_port == '21' && @.to_port == '21')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == 'tcp' && @.from_port == '445' && @.to_port == '445')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == 'tcp' && @.from_port == '445' && @.to_port == '445')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == 'udp' && @.from_port == '135' && @.to_port == '135')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == 'udp' && @.from_port == '135' && @.to_port == '135')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == '-1' && @.from_port == '137' && @.to_port == '139')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == '-1' && @.from_port == '137' && @.to_port == '139')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == 'udp' && @.from_port == '69' && @.to_port == '69')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.egress[?(@.protocol == 'udp' && @.from_port == '69' && @.to_port == '69')].ipv6_cidr_blocks[*] == ::/0
  egress {
    from_port = 69
    to_port   = 69
    protocol  = "udp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  tags = {
    yor_trace = "9e28f5ae-6911-4069-b188-e6c629139380"
  }
}
// 25. AWS Security Groups allow internet traffic from internet to RDP port (3389)
// $.resource[*].aws_security_group exists and ($.resource[*].aws_security_group[*].*[*].ingress[?( @.protocol == 'tcp' && @.from_port<3390 && @.to_port>3388 )].cidr_blocks[*] contains 0.0.0.0/0 or $.resource[*].aws_security_group[*].*[*].ingress[?( @.protocol == 'tcp' && @.from_port<3390 && @.to_port>3388)].ipv6_cidr_blocks[*] contains ::/0)
resource "aws_security_group" "allow_rdp" {
  name        = "allow_rdp"
  description = "Allow RDP inbound traffic"
  vpc_id      = aws_vpc.bar_vpc.id
  ingress {
    description = "TCP from VPC"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    ipv6_cidr_blocks = [
    "::/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  tags = {
    yor_trace = "ef0e785c-4fad-483e-bb3d-315164bc13c0"
  }
}
// 27. AWS Security Groups with Inbound rule overly permissive to All Traffic
// ($.resource[*].aws_security_group exists and ($.resource[*].aws_security_group.*[*].*.ingress[*].protocol equals -1 and ($.resource[*].aws_security_group.*[*].*.ingress[*].cidr_blocks[*] contains 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[*].ipv6_cidr_blocks[*] contains ::/0))) or ($.resource[*].aws_security_group_rule exists and ($.resource[*].aws_security_group_rule.*[*].*.protocol equals -1 and $.resource[*].aws_security_group_rule.*[*].*.type equals ingress and ($.resource[*].aws_security_group_rule.*[*].*.cidr_blocks[*] contains 0.0.0.0/0 or $.resource[*].aws_security_group_rule.*[*].*.ipv6_cidr_blocks[*] contains ::/0)))
resource "aws_security_group" "allow_all_traffic" {
  name        = "allow_rdp"
  description = "Allow RDP inbound traffic"
  vpc_id      = aws_vpc.bar_vpc.id
  ingress {
    description = "TCP from VPC"
    from_port   = 3389
    to_port     = 3389
    protocol    = "-1"
    ipv6_cidr_blocks = [
    "::/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  tags = {
    yor_trace = "3237eb70-ef68-4bfa-a850-d7f997bf759b"
  }
}
// ??? [Not Matching, Dupe of 6?] 32. AWS security groups allow ingress traffic from blocked ports
//$.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '22' && @.to_port == '22')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '22' && @.to_port == '22')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '21' && @.to_port == '21')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '21' && @.to_port == '21')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '5800' && @.to_port == '5800')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '5800' && @.to_port == '5800')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '5900' && @.to_port == '5903')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '5900' && @.to_port == '5903')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '2323' && @.to_port == '2323')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '2323' && @.to_port == '2323')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '23' && @.to_port == '23')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '23' && @.to_port == '23')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '25' && @.to_port == '25')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '25' && @.to_port == '25')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '110' && @.to_port == '110')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '110' && @.to_port == '110')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '143' && @.to_port == '143')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '143' && @.to_port == '143')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == '-1' && @.from_port == '53' && @.to_port == '53')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == '-1' && @.from_port == '53' && @.to_port == '53')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'udp' && @.from_port == '135' && @.to_port == '135')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'udp' && @.from_port == '135' && @.to_port == '135')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == '-1' && @.from_port == '137' && @.to_port == '139')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == '-1' && @.from_port == '137' && @.to_port == '139')].ipv6_cidr_blocks[*] == ::/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'udp' && @.from_port == '69' && @.to_port == '69')].cidr_blocks[*] == 0.0.0.0/0 or $.resource[*].aws_security_group.*[*].*.ingress[?(@.protocol == 'udp' && @.from_port == '69' && @.to_port == '69')].ipv6_cidr_blocks[*] == ::/0
resource "aws_security_group" "allow_udp69" {
  name        = "allow_tcp2"
  description = "Allow TCP inbound traffic"
  vpc_id      = aws_vpc.bar_vpc.id
  ingress {
    description = "TCP from VPC"
    from_port   = 69
    to_port     = 69
    protocol    = "udp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  tags = {
    yor_trace = "ba548f95-f9e3-4ce4-80c6-75c501ab4839"
  }
}

resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.foo_vpc.id
  // 28. AWS VPC NACL allows egress traffic from blocked ports
  // $.resource[*].aws_network_acl exists and $.resource[*].aws_network_acl.*[*].*.egress[?(@.protocol == 'tcp' && @.from_port == '22' && @.to_port == '22')].action==allow or $.resource[*].aws_network_acl.*[*].*.egress[?(@.protocol == 'tcp' && @.from_port == '21' && @.to_port == '21')].action==allow or $.resource[*].aws_network_acl.*[*].*.egress[?(@.protocol == 'udp' && @.from_port == '135' && @.to_port == '135')].action==allow or $.resource[*].aws_network_acl.*[*].*.egress[?(@.protocol == 'tcp' && @.from_port == '445' && @.to_port == '445')].action==allow or $.resource[*].aws_network_acl.*[*].*.egress[?(@.protocol == '-1' && @.from_port == '137' && @.to_port == '139')].action==allow or $.resource[*].aws_network_acl.*[*].*.egress[?(@.protocol == 'udp' && @.from_port == '69' && @.to_port == '69')].action==allow
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 22
    to_port    = 22
  }
  // 29. AWS VPC NACL allows traffic from blocked ports
  // $.resource[*].aws_network_acl exists and $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '22' && @.to_port == '22')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '21' && @.to_port == '21')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '5800' && @.to_port == '5800')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '5900' && @.to_port == '5903')].action==allow or  $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '2323' && @.to_port == '2323')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '23' && @.to_port == '23')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '25' && @.to_port == '25')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '110' && @.to_port == '110')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'tcp' && @.from_port == '143' && @.to_port == '143')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == '-1' && @.from_port == '53' && @.to_port == '53')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'udp' && @.from_port == '135' && @.to_port == '135')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == '-1' && @.from_port == '137' && @.to_port == '139')].action==allow or $.resource[*].aws_network_acl.*[*].*.ingress[?(@.protocol == 'udp' && @.from_port == '69' && @.to_port == '69')].action==allow
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 22
    to_port    = 22
  }
  tags = {
    yor_trace = "7b99850a-a1d8-402d-8aba-85da0b19a5a7"
  }
}
// 21. AWS Redshift does not have require_ssl configured
// $.resource[*].aws_redshift_parameter_group exists and ($.resource[*].aws_redshift_parameter_group[*].*[*].parameter[?(@.name=='require_ssl')] !exists  or $.resource[*].aws_redshift_parameter_group[*].*[*].parameter[?(@.name=='require_ssl' && @.value=='false' )] exists)
resource "aws_redshift_parameter_group" "bar" {
  name   = "parameter-group-test-terraform"
  family = "redshift-1.0"
  parameter {
    name  = "require_ssl"
    value = "false"
  }
  tags = {
    yor_trace = "991ae878-9fc9-4a22-91d4-969ccba8c239"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  // 20. AWS RDS snapshots are accessible to public (high)
  // $.resource[*].aws_db_instance exists and ($.resource[*].aws_db_instance[*].*[*].publicly_accessible !exists  or $.resource[*].aws_db_instance[*].*[*].publicly_accessible anyTrue)
  publicly_accessible = true
  tags = {
    yor_trace = "2e1637e5-7d5f-4a27-9423-d43dbf2bb322"
  }
}
// 19. AWS RDS event subscription disabled for DB security groups (medium)
// $.resource[*].aws_db_instance exists and ( $.resource[*].aws_db_event_subscription !exists or $.resource[*].aws_db_event_subscription[*].*[?(@.source_type=='db-security-group')] anyNull  or not $.resource[*].aws_db_event_subscription[*].*[?(@.source_type=='db-security-group')].enabled anyNull or $.resource[*].aws_db_event_subscription[*].*[?(@.source_type=='db-security-group')].enabled anyTrue )
resource "aws_sns_topic" "default" {
  name = "rds-events"
  tags = {
    yor_trace = "2f1d0d23-7111-49ed-a78d-b6251322efc9"
  }
}
resource "aws_db_event_subscription" "default" {
  name        = "rds-event-sub"
  sns_topic   = aws_sns_topic.default.arn
  source_type = "db-security-group"
  source_ids = [
  aws_db_instance.default.id]
  event_categories = [
    "availability",
    "deletion",
    "failover",
    "failure",
    "low storage",
    "maintenance",
    "notification",
    "read replica",
    "recovery",
    "restoration",
  ]
  enabled = false
  tags = {
    yor_trace = "7c691102-bbc1-465a-8a3e-31366a9ac8dd"
  }
}

// 4. AWS Customer Master Key (CMK) rotation is not enabled (medium)
// $.resource[*].aws_kms_key exists and ( $.resource[*].aws_kms_key[*].*[*].enable_key_rotation anyFalse or  $.resource[*].aws_kms_key[*].*[*].enable_key_rotation anyNull)
resource "aws_kms_key" "a" {
  description         = "KMS key 1"
  enable_key_rotation = false
  tags = {
    yor_trace = "34ab307e-6a21-4b20-a295-d8595ee85acc"
  }
}

// 5. AWS Default Security Group does not restrict all traffic (high)
// $.resource[*].aws_default_security_group exists and ($.resource[*].aws_default_security_group[*].*[*].ingress[*].cidr_blocks[*] contains 0.0.0.0/0 or $.resource[*].aws_default_security_group[*].*[*].ingress[*].ipv6_cidr_blocks[*] contains ::/0 or $.resource[*].aws_default_security_group[*].*[*].egress[*].cidr_blocks[*] contains 0.0.0.0/0 or $.resource[*].aws_default_security_group[*].*[*].egress[*].ipv6_cidr_blocks[*] contains ::/0)
resource "aws_vpc" "mainvpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    yor_trace = "21770732-a16c-4a45-903f-09baf40b2b46"
  }
}
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.mainvpc.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  tags = {
    yor_trace = "1af19a15-bc1e-43f1-8909-e7d4c6614440"
  }
}


data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}
resource "aws_ecs_task_definition" "github-backup" {
  family = "github-backup"
  requires_compatibilities = [
  "FARGATE"]
  network_mode  = "awsvpc"
  cpu           = 1
  memory        = 128
  task_role_arn = "${data.aws_iam_role.ecs_task_execution_role.arn}"
  // 7. AWS ECS/ Fargate task definition execution IAM Role not found (medium)
  // $.resource[*].aws_ecs_task_definition exists and $.resource[*].aws_ecs_task_definition[*].*[*].container_definitions exists and ($.resource[*].aws_ecs_task_definition[*].*[*].execution_role_arn anyNull or $.resource[*].aws_ecs_task_definition[*].*[*].execution_role_arn anyEmpty)
  execution_role_arn = ""
  // 8. AWS ECS/ Fargate task definition root user found
  // $.resource[*].aws_ecs_task_definition[*].*[*].container_definitions[?(@.user=='root')] exists
  container_definitions = <<DEFINITION
  [
    {
      "cpu": 1,
      "image": "github",
      "memory": 128,
      "name": "github-backup",
      "networkMode": "awsvpc",
      "user": "root"
    }
  ]
  DEFINITION
  tags = {
    yor_trace = "7a25de6c-a575-40fc-a407-cabde78037b9"
  }
}
resource "aws_ecs_task_definition" "github-backup2" {
  family = "github-backup"
  requires_compatibilities = [
  "FARGATE"]
  network_mode  = "awsvpc"
  cpu           = 0
  memory        = 128
  task_role_arn = "${data.aws_iam_role.ecs_task_execution_role.arn}"
  // 7. AWS ECS/ Fargate task definition execution IAM Role not found (medium)
  // $.resource[*].aws_ecs_task_definition exists and $.resource[*].aws_ecs_task_definition[*].*[*].container_definitions exists and ($.resource[*].aws_ecs_task_definition[*].*[*].execution_role_arn anyNull or $.resource[*].aws_ecs_task_definition[*].*[*].execution_role_arn anyEmpty)
  execution_role_arn = ""
  // 8. AWS ECS/ Fargate task definition root user found
  // $.resource[*].aws_ecs_task_definition[*].*[*].container_definitions[?(@.user=='root')] exists
  container_definitions = <<DEFINITION
  [
    {
      "cpu": 1,
      "image": "github",
      "memory": 128,
      "name": "github-backup",
      "networkMode": "awsvpc",
      "user": "root"
    }
  ]
  DEFINITION
  tags = {
    yor_trace = "7619eb84-1e3c-487c-8eb2-c65430ccdeb8"
  }
}

data "aws_subnet_ids" "example" {
  vpc_id = aws_vpc.mainvpc.id
}
resource "aws_elasticsearch_domain" "example" {
  domain_name           = "example"
  elasticsearch_version = "1.5"
  cluster_config {
    instance_type = "r4.large.elasticsearch"
  }
  // 9. AWS ElasticSearch cluster not in a VPC
  // $.resource[*].aws_elasticsearch_domain exists and $.resource[*].aws_elasticsearch_domain[*].*[*].vpc_options does not exist
  //  vpc_options {
  //    subnet_ids = [
  //      data.aws_subnet_ids.example.id]
  //    security_group_ids = [
  //      aws_security_group.allow_tcp.id]
  //  }
  snapshot_options {
    automated_snapshot_start_hour = 23
  }
  tags = {
    yor_trace = "02afd4ce-fd84-4fe3-bb1b-05d8425278c4"
  }
}

resource "aws_iam_account_password_policy" "strict" {
  // 10. AWS IAM password policy allows password reuse (medium)
  // $.resource[*].aws_iam_account_password_policy[*].*[*].password_reuse_prevention == 0
  password_reuse_prevention = 0
  // 11. AWS IAM password policy does not expire in 90 days (medium)
  // $.resource[*].aws_iam_account_password_policy[*].*[?( @.max_password_age>90 )] is not empty
  max_password_age = 91
  // 12. AWS IAM password policy does not have a minimum of 14 characters (medium)
  // $.resource[*].aws_iam_account_password_policy[*].*[?( @.minimum_password_length<14 )] is not empty
  minimum_password_length = 8
  // 13. AWS IAM password policy does not have a lowercase character (medium)
  // $.resource[*].aws_iam_account_password_policy[*].*[*]
  require_lowercase_characters = false
  // 14. AWS IAM password policy does not have a number (medium)
  // $.resource[*].aws_iam_account_password_policy[*].*[*].require_numbers anyFalse
  require_numbers = false
  // 15. AWS IAM password policy does not have a symbol (medium)
  //$.resource[*].aws_iam_account_password_policy[*].*[*].require_symbols anyFalse
  require_symbols = false
  // 16. AWS IAM password policy does not have a uppercase character (medium)
  // $.resource[*].aws_iam_account_password_policy[*].*[*].require_uppercase_characters anyFalse
  require_uppercase_characters   = false
  allow_users_to_change_password = true
}

// 17. AWS IAM policy attached to users (low)
// $.resource[*].aws_iam_policy_attachment[*].*[*].users exists and $.resource[*].aws_iam_policy_attachment[*].*[*].users[*] is not empty
resource "aws_iam_policy_attachment" "test-attach" {
  name = "test-attachment"
  users = [
  "test-user"]
  roles = [
  "test-role"]
  groups = [
  "test-group"]
  policy_arn = "arn:aws:kms:us-west-2:111122223333:key"
}

// 18. AWS EKS unsupported Master node version (high)
// $.resource[*].aws_eks_cluster[*].*[*].version anyStartWith 1.9.
resource "aws_eks_cluster" "example" {
  name     = "example"
  role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  vpc_config {
    subnet_ids = [
    data.aws_subnet_ids.example.id]
  }
  version = "1.9.9"
  tags = {
    yor_trace = "36426b40-55ac-41e4-9025-2f6058247849"
  }
}