data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "aws_vpc" "default" {
  default = true
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Security group for web servers"
  vpc_id      = data.aws_vpc.default.id

  # Inbound HTTP
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}


resource "aws_instance" "ec2-web" {
ami           = data.aws_ami.amazon_linux_2023.id
vpc_security_group_ids = [  aws_security_group.web_sg.id ]
instance_type = "t2.small"
availability_zone = "us-east-1a"

# Docker install and run container user data
user_data = <<-EOF
#! /bin/sh
dnf update -y
dnf install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
docker run -d -p 80:8501 XXXXXXXXXX/demo-devops 
EOF

tags = {
Name = "first-ec2-server"
}
}
output "server_private_ip" {
value = aws_instance.ec2-web.private_ip
}
output "server_public_ipv4" {
value = aws_instance.ec2-web.public_ip
}
output "server_id" {
value = aws_instance.ec2-web.id
}
