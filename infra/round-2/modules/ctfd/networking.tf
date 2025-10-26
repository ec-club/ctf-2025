resource "aws_subnet" "ctfd" {
  vpc_id          = var.vpc_id
  cidr_block      = cidrsubnet(var.vpc_ipv4_cidr_block, 8, var.ctfd_subnet_index)
  ipv6_cidr_block = cidrsubnet(var.vpc_ipv6_cidr_block, 8, var.ctfd_subnet_index)
  tags = {
    Name = "CTFd subnet"
  }
}
resource "aws_route_table_association" "ctfd" {
  subnet_id      = aws_subnet.ctfd.id
  route_table_id = var.public_route_table_id
}

resource "aws_subnet" "ctfd-private-primary" {
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_ipv4_cidr_block, 8, var.ctfd_internal_subnet_indices[0])
  availability_zone       = aws_subnet.ctfd.availability_zone
  ipv6_cidr_block         = cidrsubnet(var.vpc_ipv6_cidr_block, 8, var.ctfd_internal_subnet_indices[0])
  map_public_ip_on_launch = false
  tags = {
    Name = "CTFd private subnet - Primary"
  }
}
resource "aws_subnet" "ctfd-private-secondary" {
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_ipv4_cidr_block, 8, var.ctfd_internal_subnet_indices[1])
  availability_zone       = endswith(aws_subnet.ctfd.availability_zone, "a") ? "${substr(aws_subnet.ctfd.availability_zone, 0, length(aws_subnet.ctfd.availability_zone) - 1)}b" : "${substr(aws_subnet.ctfd.availability_zone, 0, length(aws_subnet.ctfd.availability_zone) - 1)}a"
  ipv6_cidr_block         = cidrsubnet(var.vpc_ipv6_cidr_block, 8, var.ctfd_internal_subnet_indices[1])
  map_public_ip_on_launch = false
  tags = {
    Name = "CTFd private subnet - Secondary"
  }
}
