terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}
provider "aws" {
  region  = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/24"
  instance_tenancy = "default"

  tags = {
    Name = "cwc-vpc"
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/25"

  tags = {
    Name = "cwc-public-subnet"
  }
}
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.128/25"

  tags = {
    Name = "cwc-private-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "cwc-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "cwc-public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "key" {
  key_name   = "cwc-key"
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "local_file" "tf_key" {
  content  = tls_private_key.private_key.private_key_pem
  filename = "cwc-key.pem"

}

resource "aws_instance" "public_instance" {
  ami           = "ami-02457590d33d576c3"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  tags = {
    Name = "cwc-public-ec2"
  }
}

