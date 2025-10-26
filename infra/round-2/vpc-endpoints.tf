resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.ctf.id
  service_name      = "com.amazonaws.${local.workspace.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_default_route_table.ctf.id,
    aws_route_table.nat_gateway.id,
    aws_route_table.public.id
  ]

  tags = {
    Name = "S3 Gateway VPC Endpoint"
  }
}

resource "aws_subnet" "aws-endpoints" {
  vpc_id     = aws_vpc.ctf.id
  cidr_block = cidrsubnet(aws_vpc.ctf.cidr_block, 8, local.aws_endpoints_subnet_index)
  tags = {
    Name = "AWS Endpoints Subnet"
  }
}
resource "aws_security_group" "aws-ec2-instance-connect-endpoint" {
  name        = "AWS EC2 Instance Connect Endpoint SG"
  description = "Security group for AWS EC2 Instance Connect Endpoint"
  vpc_id      = aws_vpc.ctf.id

  egress {
    protocol         = "tcp"
    from_port        = 22
    to_port          = 22
    cidr_blocks      = [aws_vpc.ctf.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.ctf.ipv6_cidr_block]
  }
}
resource "aws_ec2_instance_connect_endpoint" "private" {
  subnet_id          = aws_subnet.aws-endpoints.id
  preserve_client_ip = false # Not supported for dualstack endpoints
  security_group_ids = [aws_security_group.aws-ec2-instance-connect-endpoint.id]
  tags = {
    Name = "EC2 Instance Connect Endpoint"
  }
}

resource "aws_security_group" "aws-endpoint" {
  name        = "AWS Endpoints SG"
  description = "Security group for AWS VPC endpoints"
  vpc_id      = aws_vpc.ctf.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "ALL"
    cidr_blocks      = [aws_vpc.ctf.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.ctf.ipv6_cidr_block]
  }
}
resource "aws_vpc_endpoint" "aws-services" {
  vpc_id              = aws_vpc.ctf.id
  service_name        = "com.amazonaws.${local.workspace.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = [aws_subnet.aws-endpoints.id]
  security_group_ids = [aws_security_group.aws-endpoint.id]

  # See: https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html
  for_each = toset(["ecr.api", "ecr.dkr", "s3", "kms"])
  tags = {
    Name = "${each.value} VPC interface endpoint"
  }
}
