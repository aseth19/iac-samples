provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.network_config
  tags = {
    Name      = var.network_config
    Env       = "prod"
    yor_trace = "68d83f57-28e4-413d-8265-3ceca3750ecb"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.network_config
  availability_zone = "us-west-2a"
  tags = {
    Name      = var.network_config
    Env       = "prod"
    yor_trace = "cb73ba28-55d3-4d80-8f02-529095722ef5"
  }
}
