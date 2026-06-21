resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id

  tags = {
    Name                     = "${local.name_prefix}-public-${each.value.az}"
    "kubernetes.io/role/elb" = "1"
    TrustZone                = "public"
  }
}

resource "aws_subnet" "application" {
  for_each = local.application_subnets

  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main.id

  tags = {
    Name                              = "${local.name_prefix}-application-${each.value.az}"
    "kubernetes.io/role/internal-elb" = "1"
    TrustZone                         = "application"
  }
}

resource "aws_subnet" "data" {
  for_each = local.data_subnets

  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main.id

  tags = {
    Name      = "${local.name_prefix}-data-${each.value.az}"
    TrustZone = "data"
  }
}

resource "aws_subnet" "production" {
  for_each = local.production_subnets

  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.main.id

  tags = {
    Name      = "${local.name_prefix}-production-${each.value.az}"
    TrustZone = "production"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[var.availability_zones[0]].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${local.name_prefix}-nat"
  }
}

resource "aws_route_table" "application" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  dynamic "route" {
    for_each = var.enable_vpn_routing_mode ? [1] : []

    content {
      cidr_block           = var.vpn_client_cidr
      network_interface_id = aws_instance.openvpn.primary_network_interface_id
    }
  }

  tags = {
    Name = "${local.name_prefix}-application-rt"
  }
}

resource "aws_route_table_association" "application" {
  for_each = aws_subnet.application

  route_table_id = aws_route_table.application.id
  subnet_id      = each.value.id
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_vpn_routing_mode ? [1] : []

    content {
      cidr_block           = var.vpn_client_cidr
      network_interface_id = aws_instance.openvpn.primary_network_interface_id
    }
  }

  tags = {
    Name = "${local.name_prefix}-data-rt"
  }
}

resource "aws_route_table_association" "data" {
  for_each = aws_subnet.data

  route_table_id = aws_route_table.data.id
  subnet_id      = each.value.id
}

resource "aws_route_table" "production" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  dynamic "route" {
    for_each = var.enable_vpn_routing_mode ? [1] : []

    content {
      cidr_block           = var.vpn_client_cidr
      network_interface_id = aws_instance.openvpn.primary_network_interface_id
    }
  }

  tags = {
    Name = "${local.name_prefix}-production-rt"
  }
}

resource "aws_route_table_association" "production" {
  for_each = aws_subnet.production

  route_table_id = aws_route_table.production.id
  subnet_id      = each.value.id
}
