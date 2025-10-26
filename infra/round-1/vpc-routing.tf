resource "aws_internet_gateway" "ctf" {
  vpc_id = aws_vpc.ctf.id
  tags = {
    Name = "CTF internet gateway"
  }
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
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ctf.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.ctf.id
  }

  tags = {
    Name = "CTF VPC default route table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ctf.id

  route {
    cidr_block = aws_vpc.ctf.cidr_block
    gateway_id = "local"
  }
  route {
    ipv6_cidr_block = aws_vpc.ctf.ipv6_cidr_block
    gateway_id      = "local"
  }

  tags = {
    Name = "Private route table"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.ctf.id
  cidr_block              = cidrsubnet(aws_vpc.ctf.cidr_block, 8, 254)
  ipv6_cidr_block         = cidrsubnet(aws_vpc.ctf.ipv6_cidr_block, 8, 254)
  map_public_ip_on_launch = true
  tags = {
    Name = "Public subnet"
  }
}
