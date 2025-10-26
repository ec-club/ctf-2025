locals {
  singapore_region = "ap-southeast-1"
}

resource "aws_vpc" "ctf-singapore" {
  region = local.singapore_region

  cidr_block                       = "10.1.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  tags = {
    Name = "CTF VPC [Singapore] (${terraform.workspace})"
  }
}
resource "aws_internet_gateway" "ctf-singapore" {
  region = local.singapore_region

  vpc_id = aws_vpc.ctf-singapore.id
  tags = {
    Name = "CTF VPC Internet Gateway"
  }
}

resource "aws_vpc_peering_connection" "ctf_peering" {
  region      = local.workspace.region
  vpc_id      = aws_vpc.ctf.id
  peer_vpc_id = aws_vpc.ctf-singapore.id
  peer_region = local.singapore_region
  tags = {
    Name = "CTF VPC Peering (${terraform.workspace})"
  }
}
resource "aws_vpc_peering_connection_accepter" "ctf_peering" {
  region = local.singapore_region

  vpc_peering_connection_id = aws_vpc_peering_connection.ctf_peering.id
  auto_accept               = true
  tags = {
    Name = "CTF VPC Peering Accepter (${terraform.workspace})"
  }
}

resource "aws_default_route_table" "ctf-singapore" {
  region = "ap-southeast-1"

  default_route_table_id = aws_vpc.ctf-singapore.default_route_table_id
  route {
    cidr_block = aws_vpc.ctf-singapore.cidr_block
    gateway_id = "local"
  }
  route {
    ipv6_cidr_block = aws_vpc.ctf-singapore.ipv6_cidr_block
    gateway_id      = "local"
  }
  route {
    cidr_block                = aws_vpc.ctf.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.ctf_peering.id
  }
  route {
    ipv6_cidr_block           = aws_vpc.ctf.ipv6_cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.ctf_peering.id
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ctf-singapore.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.ctf-singapore.id
  }
  tags = {
    Name = "CTF VPC default route table (Singapore)"
  }
}
