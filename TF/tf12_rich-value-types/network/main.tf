provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.network_config
  tags = {
    Name      = var.network_config
    Env       = "prod"
    yor_trace = "f2d08eca-fed5-4770-851a-f19b75a82639"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.network_config
  availability_zone = "us-west-2a"
  tags = {
    Name      = var.network_config
    Env       = "prod"
    yor_trace = "c999ab82-de1a-430a-8376-4d77e5dd61e7"
  }
}
