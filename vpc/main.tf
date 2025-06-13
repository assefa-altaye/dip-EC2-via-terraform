resource "aws_vpc" "main" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "cwc-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/25"

  availability_zone = "us-east-1a"

  tags = {
    Name = "cwc-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.128/25"

  availability_zone = "us-east-1a"

  tags = {
    Name = "cwc-private-subnet"
  }
}