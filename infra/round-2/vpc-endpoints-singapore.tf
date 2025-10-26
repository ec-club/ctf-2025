resource "aws_vpc_endpoint" "s3-singapore" {
  region = aws_vpc.ctf-singapore.region
  vpc_id = aws_vpc.ctf-singapore.id

  service_name      = "com.amazonaws.${aws_vpc.ctf-singapore.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_default_route_table.ctf-singapore.id]
  tags = {
    Name = "S3 Gateway VPC Endpoint"
  }
}

resource "aws_subnet" "aws-endpoints-singapore" {
  region     = aws_vpc.ctf-singapore.region
  vpc_id     = aws_vpc.ctf-singapore.id
  cidr_block = cidrsubnet(aws_vpc.ctf-singapore.cidr_block, 8, local.aws_endpoints_subnet_index)
  tags = {
    Name = "AWS Endpoints Subnet"
  }
}

resource "aws_security_group" "aws-endpoint-singapore" {
  region      = aws_vpc.ctf-singapore.region
  name        = "AWS Endpoints SG"
  description = "Security group for AWS VPC endpoints"
  vpc_id      = aws_vpc.ctf-singapore.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "ALL"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
resource "aws_vpc_endpoint" "aws-services-singapore" {
  region = aws_vpc.ctf-singapore.region
  vpc_id = aws_vpc.ctf-singapore.id

  service_name        = "com.amazonaws.${aws_vpc.ctf-singapore.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = [aws_subnet.aws-endpoints-singapore.id]
  security_group_ids = [aws_security_group.aws-endpoint-singapore.id]

  # See: https://docs.aws.amazon.com/AmazonECR/latest/userguide/vpc-endpoints.html
  for_each   = toset(["ecr.api", "ecr.dkr", "s3"])
  depends_on = [aws_vpc_endpoint.s3-singapore]
  tags = {
    Name = "${each.value} VPC interface endpoint"
  }
}
