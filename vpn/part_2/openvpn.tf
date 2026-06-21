data "aws_ami" "openvpn_access_server" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "product-code"
    values = ["f2ew2wrz425a1jagnifd02u5t"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "openvpn" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "openvpn" {
  key_name   = "${local.name_prefix}-openvpn"
  public_key = tls_private_key.openvpn.public_key_openssh
}

resource "local_sensitive_file" "openvpn_private_key" {
  content         = tls_private_key.openvpn.private_key_pem
  filename        = "${path.module}/${local.name_prefix}-openvpn.pem"
  file_permission = "0600"
}

resource "aws_instance" "openvpn" {
  ami                    = data.aws_ami.openvpn_access_server.id
  instance_type          = var.openvpn_instance_type
  key_name               = aws_key_pair.openvpn.key_name
  subnet_id              = aws_subnet.public[var.availability_zones[0]].id
  vpc_security_group_ids = [aws_security_group.openvpn.id]

  source_dest_check = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 16
    volume_type = "gp3"
  }

  tags = {
    Name = "${local.name_prefix}-openvpn"
  }
}

resource "aws_eip" "openvpn" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-openvpn-eip"
  }
}

resource "aws_eip_association" "openvpn" {
  allocation_id = aws_eip.openvpn.id
  instance_id   = aws_instance.openvpn.id
}
