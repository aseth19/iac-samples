terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name      = "tf-0.12-for-example"
    Env       = "prod"
    yor_trace = "2db1f322-54ef-4df5-b6d9-4f0def67b758"
  }
}

resource "aws_s3_bucket" "publics3" {
  acl    = var.acl
  bucket = "publics3"
  versioning {
    enabled = true
  }
  tags = {
    Env       = "prod"
    yor_trace = "2a515f56-aca9-4c01-9043-82be399b2d8c"
  }
}

resource "aws_security_group" "allow_tcp" {
  name        = "allow_tcp"
  description = "Allow TCP inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    description = "TCP from VPC"
    // AWS Security Groups allow internet traffic to SSH port (22)
    from_port = 99
    to_port   = 99
    protocol  = "tcp"
    cidr_blocks = [
    var.cidr]
  }
  tags = {
    Env       = "prod"
    yor_trace = "bb2acd3e-b203-4af6-93d3-d4c4c726238e"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name      = "tf-0.12-for-example"
    Env       = "prod"
    yor_trace = "9cbaf447-27b6-4ef7-bc88-59be8623f93f"
  }
}

resource "aws_instance" "ubuntu" {
  count                       = 3
  ami                         = "ami-2e1ef954"
  instance_type               = "t2.micro"
  associate_public_ip_address = (count.index == 1 ? true : false)
  subnet_id                   = aws_subnet.my_subnet.id
  tags = {
    Name      = format("terraform-0.12-for-demo-%d", count.index)
    Env       = "prod"
    yor_trace = "781af293-0374-4ca2-a057-4d30f46c3188"
  }
}

# This uses the old splat expression
output "private_addresses_old" {
  value = aws_instance.ubuntu.*.private_dns
}

# This uses the new full splat operator (*)
# But this does not work in 0.12 alpha-1 or alpha-2
/*output "private_addresses_full_splat" {
  value = [ aws_instance.ubuntu[*].private_dns ]
}*/

# This uses the new for expression
output "private_addresses_new" {
  value = [
    for instance in aws_instance.ubuntu :
    instance.private_dns
  ]
}

# This uses the new conditional operator
# that can work with lists
# It should work with lists in [x, y, z] form, but does not yet do that
output "ips" {
  value = [
    for instance in aws_instance.ubuntu :
    (instance.public_ip != "" ? list(instance.private_ip, instance.public_ip) : list(instance.private_ip))
  ]
}
