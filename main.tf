#The comments in this code are left intentionally for learning purpose
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls ={
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local ={
      source = "hashicorp/local"
      version = "~>2.5"
    }
    http ={
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

# provider "tls" {}

# provider "local" {}

# provider "http" {}

# data "http" "myip" {
#   url = "https://ipinfo.io/json"
# }

module "vpc" {
  source = "./vpc"

  region = var.region
  cidr_block = var.cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  app_name = var.app_name
}

# output "myip" {
#   value = jsondecode(data.http.myip.response_body).ip
# }

# resource "tls_private_key" "private_key" {
#   algorithm = "RSA"
#   rsa_bits = 4096
# }

# resource "aws_key_pair" "key" {
#   key_name   = "cwc-key"
#   public_key = tls_private_key.private_key.public_key_openssh
# }

# resource "local_file" "tf_key" {
#   content  = tls_private_key.private_key.private_key_pem
#   filename = "cwc-key.pem"
# }

# resource "aws_security_group" "cwc_public_sg" {
#   name = "cwc_public_sg"
#   description = "Allow SSH and TCP inbound traffic and all outbound traffic"
#   vpc_id      = module.vpc.vpc_id

#   ingress  {
#     from_port = 22
#     to_port =22 
#     protocol ="tcp"
#     cidr_blocks =[format("%s/32", jsondecode(data.http.myip.response_body).ip)]
#   }

#   ingress  {
#     from_port = 80
#     to_port =80
#     protocol ="tcp"
#     cidr_blocks =["0.0.0.0/0"]
#   }

#   egress {
#     from_port = 0
#     to_port =0
#     protocol ="-1"
#     cidr_blocks =["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "cwc-public-sg"
#   }
# }

# resource "aws_instance" "public_instance" {
#   ami           = "ami-02457590d33d576c3"
#   instance_type = "t3.micro"

#   subnet_id = module.vpc.public_subnet_ids[0]

#   associate_public_ip_address = true

#   key_name = aws_key_pair.key.key_name

#   vpc_security_group_ids = [aws_security_group.cwc_public_sg.id]

#   tags = {
#     Name = "cwc-public-ec2"
#   }
# }

resource "aws_security_group" "private_sg" {
  name = "${var.app_name}-private-sg"
  description = "Private SG"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${var.app_name}-private-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_traffic_from_lb" {
  security_group_id = aws_security_group.private_sg.id
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
  referenced_security_group_id = aws_security_group.lb_sg.id
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_to_private" {
  security_group_id = aws_security_group.private_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  # from_port = 80
  # to_port = 80
  ip_protocol = "-1"
}

# resource "aws_security_group" "cwc_private_sg" {
#   name = "cwc_private_sg"
#   description = "Allow TCP inbound traffic from public subnet, and all outbound traffic"
#   vpc_id      = module.vpc.vpc_id

#   # ingress  {
#   #   from_port = 22
#   #   to_port =22 
#   #   protocol ="tcp"
#   #   security_groups  =[aws_security_group.cwc_bastion_host_sg.id]
#   # }

#   ingress  {
#     from_port = 80
#     to_port =80
#     protocol ="tcp"
#     security_groups = [aws_security_group.lb_sg.id]
#   }

#   egress {
#     from_port = 0
#     to_port =0
#     protocol ="-1"
#     cidr_blocks =["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "cwc-private-sg"
#   }
# }

resource "aws_instance" "private_instance" {
  count = 2
  ami           = "ami-02457590d33d576c3"
  instance_type = "t3.micro"

  subnet_id = module.vpc.private_subnet_ids[count.index]

  associate_public_ip_address = false

  # key_name = aws_key_pair.key.key_name

  vpc_security_group_ids = [aws_security_group.private_sg.id]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("./script.sh", {
    instance_id = count.index + 1
  })

  tags = {
    Name = "${var.app_name}-private-ec2-${count.index + 1}"
  }
}

# resource "aws_security_group" "cwc_bastion_host_sg" {
#   name = "cwc_bastion_host_sg"
#   description = "Allow SSH traffic from my IP address and all outbound traffic"
#   vpc_id      = module.vpc.vpc_id

#   ingress  {
#     from_port = 22
#     to_port =22 
#     protocol ="tcp"
#     cidr_blocks =[format("%s/32", jsondecode(data.http.myip.response_body).ip)]
#   }

#   egress {
#     from_port = 0
#     to_port =0
#     protocol ="-1"
#     cidr_blocks =["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "cwc-private-sg"
#   }
# }

# resource "aws_instance" "bastion_host" {
#   ami           = "ami-02457590d33d576c3"
#   instance_type = "t3.micro"

#   subnet_id = module.vpc.public_subnet_ids[0]

#   associate_public_ip_address = true

#   key_name = aws_key_pair.key.key_name

#   vpc_security_group_ids = [aws_security_group.cwc_bastion_host_sg.id]

#   tags = {
#     Name = "cwc-bastion-host-ec2"
#   }
# }

resource "aws_iam_role" "ec2_role" {
  name = "${var.app_name}-ec2-role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.app_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_security_group" "lb_sg" {
  name = "${var.app_name}-lb-sg"
  description = "Load balancer SG"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "${var.app_name}-lb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_traffic" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_to_lb" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  to_port = 80
  ip_protocol = "-1"
}

resource "aws_lb" "load_balancer" {
  name = "${var.app_name}-load-balancer"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.lb_sg.id]
  subnets = module.vpc.public_subnet_ids
}

resource "aws_lb_target_group" "target_group" {
  name = "${var.app_name}-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "target-group-attachment" {
  count = 2
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id = aws_instance.private_instance[count.index].id
  port = 80
}

resource "aws_lb_listener" "listner" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}