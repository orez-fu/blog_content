resource "aws_security_group" "openvpn" {
  name_prefix = "${local.name_prefix}-openvpn-"
  description = "OpenVPN Access Server"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-openvpn-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "openvpn_udp" {
  security_group_id = aws_security_group.openvpn.id
  description       = "OpenVPN UDP tunnel"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 1194
  ip_protocol       = "udp"
  to_port           = 1194
}

resource "aws_vpc_security_group_ingress_rule" "openvpn_https" {
  security_group_id = aws_security_group.openvpn.id
  description       = "OpenVPN HTTPS tunnel and client UI"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "openvpn_admin" {
  for_each = toset(var.admin_cidr_blocks)

  security_group_id = aws_security_group.openvpn.id
  description       = "OpenVPN Admin UI from a trusted network"
  cidr_ipv4         = each.value
  from_port         = 943
  ip_protocol       = "tcp"
  to_port           = 943
}

resource "aws_vpc_security_group_ingress_rule" "openvpn_ssh" {
  for_each = toset(var.admin_cidr_blocks)

  security_group_id = aws_security_group.openvpn.id
  description       = "SSH from a trusted network"
  cidr_ipv4         = each.value
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "openvpn_all" {
  security_group_id = aws_security_group.openvpn.id
  description       = "OpenVPN egress to VPC resources and the internet"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "RDS MySQL access from OpenVPN"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_openvpn" {
  security_group_id            = aws_security_group.rds.id
  description                  = "MySQL from the OpenVPN Access Server"
  referenced_security_group_id = aws_security_group.openvpn.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

resource "aws_vpc_security_group_ingress_rule" "rds_mysql_from_vpn_clients" {
  security_group_id = aws_security_group.rds.id
  description       = "MySQL from the routed OpenVPN client pool"
  cidr_ipv4         = var.vpn_client_cidr
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
}

resource "aws_security_group" "internal_alb" {
  name_prefix = "${local.name_prefix}-internal-alb-"
  description = "Internal ALB access from OpenVPN"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-internal-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "internal_alb_http_from_openvpn" {
  security_group_id            = aws_security_group.internal_alb.id
  description                  = "HTTP from the OpenVPN Access Server"
  referenced_security_group_id = aws_security_group.openvpn.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
}

resource "aws_vpc_security_group_ingress_rule" "internal_alb_http_from_vpn_clients" {
  security_group_id = aws_security_group.internal_alb.id
  description       = "HTTP from the routed OpenVPN client pool"
  cidr_ipv4         = var.vpn_client_cidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "internal_alb_all" {
  security_group_id = aws_security_group.internal_alb.id
  description       = "ALB egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "eks_control_plane" {
  name_prefix = "${local.name_prefix}-eks-api-"
  description = "Additional access controls for the EKS private API"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-eks-api-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_api_from_openvpn" {
  security_group_id            = aws_security_group.eks_control_plane.id
  description                  = "EKS HTTPS API from the OpenVPN Access Server"
  referenced_security_group_id = aws_security_group.openvpn.id
  from_port                    = 443
  ip_protocol                  = "tcp"
  to_port                      = 443
}

resource "aws_vpc_security_group_ingress_rule" "eks_api_from_vpn_clients" {
  security_group_id = aws_security_group.eks_control_plane.id
  description       = "EKS HTTPS API from the routed OpenVPN client pool"
  cidr_ipv4         = var.vpn_client_cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "eks_control_plane_all" {
  security_group_id = aws_security_group.eks_control_plane.id
  description       = "EKS control plane egress"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
