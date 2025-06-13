variable "region" {
  type = string
  description = "The region where the VPC is created"
  default = "us-east-1"
}

variable "cidr_block" {
  type = string
  description = "value of cidr block"
  default = "10.0.0.0/24"
}