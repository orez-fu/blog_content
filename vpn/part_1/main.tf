terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

################################################
# Networkin
#################################################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpn-demo-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "vpn-demo-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet"
  }
}


# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "openvpn" {
  name        = "openvpn-sg"
  description = "OpenVPN Access Server"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "OpenVPN UDP"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Admin UI"
    from_port   = 943
    to_port     = 943
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS VPN"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "openvpn-sg"
  }
}

resource "aws_security_group" "private_ec2" {
  name        = "private-ec2-sg"
  description = "Private EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-ec2-sg"
  }
}

# EC2 Instances
# OpenVPN Access Server / Self-Hosted VPN (BYOL)
data "aws_ami" "openvpn_access_server" {
  most_recent = true

  owners = ["679593333241"]

  filter {
    name   = "name"
    values = ["OpenVPN Access Server Community Image-fe8020db-5343-4c43-9e65-5ed4a825c931"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "product-code"
    values = ["f2ew2wrz425a1jagnifd02u5t"]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
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

resource "tls_private_key" "vpn_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "vpn_ssh" {
  key_name   = "vpn-demo-ssh-key"
  public_key = tls_private_key.vpn_ssh.public_key_openssh

  tags = {
    Name = "vpn-demo-ssh-key"
  }
}

resource "local_sensitive_file" "vpn_ssh_private_key" {
  content         = tls_private_key.vpn_ssh.private_key_pem
  filename        = "${path.module}/vpn-demo-ssh-key.pem"
  file_permission = "0600"
}

resource "aws_instance" "openvpn" {
  ami                         = data.aws_ami.openvpn_access_server.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.vpn_ssh.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.openvpn.id]
  user_data_replace_on_change = true

  user_data = <<EOF
#!/bin/bash
set -euo pipefail

install -d -m 700 /root/.ssh
cat > /root/.ssh/private-test-server.pem <<'KEY'
${tls_private_key.vpn_ssh.private_key_pem}
KEY
chmod 600 /root/.ssh/private-test-server.pem
cp /root/.ssh/private-test-server.pem /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa

if id openvpnas >/dev/null 2>&1; then
  install -d -m 700 -o openvpnas -g openvpnas /home/openvpnas/.ssh
  cp /root/.ssh/private-test-server.pem /home/openvpnas/.ssh/private-test-server.pem
  cp /root/.ssh/private-test-server.pem /home/openvpnas/.ssh/id_rsa
  chown openvpnas:openvpnas /home/openvpnas/.ssh/private-test-server.pem
  chown openvpnas:openvpnas /home/openvpnas/.ssh/id_rsa
  chmod 600 /home/openvpnas/.ssh/private-test-server.pem
  chmod 600 /home/openvpnas/.ssh/id_rsa
fi

EOF

  tags = {
    Name = "openvpn-access-server"
  }
}

resource "aws_instance" "private_ec2" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.vpn_ssh.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_ec2.id]

  tags = {
    Name = "private-test-server"
  }
}

# Elastic IP
resource "aws_eip" "openvpn" {
  domain = "vpc"

  tags = {
    Name = "openvpn-eip"
  }
}

resource "aws_eip_association" "openvpn" {
  allocation_id = aws_eip.openvpn.id
  instance_id   = aws_instance.openvpn.id
}

# Outputs
output "openvpn_public_ip" {
  value = aws_eip.openvpn.public_ip
}

output "private_ec2_ip" {
  value = aws_instance.private_ec2.private_ip
}

output "private_ec2_ssh_command" {
  value = "ssh -i ${local_sensitive_file.vpn_ssh_private_key.filename} ec2-user@${aws_instance.private_ec2.private_ip}"
}

output "ssh_key_pair_name" {
  value = aws_key_pair.vpn_ssh.key_name
}

output "ssh_private_key_file" {
  value = local_sensitive_file.vpn_ssh_private_key.filename
}

output "ssh_private_key_pem" {
  value     = tls_private_key.vpn_ssh.private_key_pem
  sensitive = true
}
