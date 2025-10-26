resource "aws_vpc" "ctf" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  tags = {
    Name = "CTF VPC (${terraform.workspace})"
  }
}
resource "aws_internet_gateway" "ctf" {
  vpc_id = aws_vpc.ctf.id
  tags = {
    Name = "CTF VPC Internet Gateway"
  }
}

locals {
  ctfd_subnet_index            = 0
  ctfd_internal_subnet_1_index = 1
  ctfd_internal_subnet_2_index = 2

  challenges_subnet_index           = 3
  challenges_subnet_index_singapore = 4

  monitoring_subnet_index          = 252
  monitoring_internal_subnet_index = 253
  nat_gateway_subnet_index         = 254
  aws_endpoints_subnet_index       = 255
}

resource "aws_default_route_table" "ctf" {
  default_route_table_id = aws_vpc.ctf.default_route_table_id
  route {
    cidr_block = aws_vpc.ctf.cidr_block
    gateway_id = "local"
  }
  route {
    ipv6_cidr_block = aws_vpc.ctf.ipv6_cidr_block
    gateway_id      = "local"
  }
  tags = {
    Name = "CTF VPC default route table"
  }
}

resource "aws_eip" "ctf_nat" {
  tags = {
    Name = "CTF NAT Gateway EIP"
  }
}
resource "aws_subnet" "nat_gateway" {
  vpc_id          = aws_vpc.ctf.id
  cidr_block      = cidrsubnet(aws_vpc.ctf.cidr_block, 8, local.nat_gateway_subnet_index)
  ipv6_cidr_block = cidrsubnet(aws_vpc.ctf.ipv6_cidr_block, 8, local.nat_gateway_subnet_index)
  tags = {
    Name = "Subnet for NAT Gateway"
  }
}
resource "aws_nat_gateway" "ctf" {
  allocation_id = aws_eip.ctf_nat.id
  subnet_id     = aws_subnet.nat_gateway.id
  tags = {
    Name = "CTF VPC NAT Gateway"
  }
}
resource "aws_egress_only_internet_gateway" "ctf" {
  vpc_id = aws_vpc.ctf.id
  tags = {
    Name = "CTF VPC Egress-Only Internet Gateway"
  }
}

resource "aws_route_table" "nat_gateway" {
  vpc_id = aws_vpc.ctf.id
  route {
    cidr_block = aws_vpc.ctf.cidr_block
    gateway_id = "local"
  }
  route {
    ipv6_cidr_block = aws_vpc.ctf.ipv6_cidr_block
    gateway_id      = "local"
  }
  route {
    cidr_block                = aws_vpc.ctf-singapore.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.ctf_peering.id
  }
  route {
    ipv6_cidr_block           = aws_vpc.ctf-singapore.ipv6_cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.ctf_peering.id
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ctf.id
  }
  route {
    ipv6_cidr_block = "64:ff9b::/96"
    nat_gateway_id  = aws_nat_gateway.ctf.id
  }
  route {
    ipv6_cidr_block        = "::/0"
    egress_only_gateway_id = aws_egress_only_internet_gateway.ctf.id
  }
  tags = {
    Name = "CTF NAT Gateway Route Table"
  }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ctf.id
  route {
    cidr_block = aws_vpc.ctf.cidr_block
    gateway_id = "local"
  }
  route {
    ipv6_cidr_block = aws_vpc.ctf.ipv6_cidr_block
    gateway_id      = "local"
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ctf.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.ctf.id
  }
  tags = {
    Name = "CTF NAT Gateway Route Table"
  }
}
