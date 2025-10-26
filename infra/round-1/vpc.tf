resource "aws_vpc" "ctf" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  tags = {
    Name = "CTF VPC"
  }
}

resource "aws_subnet" "ctfd" {
  vpc_id = aws_vpc.ctf.id

  cidr_block              = "10.0.1.0/24"
  ipv6_cidr_block         = cidrsubnet(aws_vpc.ctf.ipv6_cidr_block, 8, 0)
  map_public_ip_on_launch = false
  tags = {
    Name = "CTFd subnet"
  }
}
resource "aws_route_table_association" "ctfd" {
  subnet_id      = aws_subnet.ctfd.id
  route_table_id = aws_vpc.ctf.default_route_table_id
}

resource "aws_subnet" "aws-endpoints" {
  vpc_id                  = aws_vpc.ctf.id
  cidr_block              = "10.0.255.0/24"
  ipv6_cidr_block         = cidrsubnet(aws_vpc.ctf.ipv6_cidr_block, 8, 255)
  map_public_ip_on_launch = false
  tags = {
    Name = "Subnet for AWS VPC endpoints"
  }
}
resource "aws_route_table_association" "aws-endpoints" {
  subnet_id      = aws_subnet.aws-endpoints.id
  route_table_id = aws_route_table.private.id
}
resource "aws_security_group" "aws-endpoint" {
  name        = "AWS Endpoints SG"
  description = "Security group for AWS VPC endpoints"
  vpc_id      = aws_vpc.ctf.id

  egress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "ALL"
    cidr_blocks      = [aws_vpc.ctf.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.ctf.ipv6_cidr_block]
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.ctf.id
  service_name      = "com.amazonaws.${local.workspace.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id,
    aws_default_route_table.ctf.id,
  ]

  tags = {
    Name = "S3 Gateway VPC Endpoint"
  }
}
resource "aws_vpc_endpoint" "aws-services" {
  vpc_id              = aws_vpc.ctf.id
  service_name        = "com.amazonaws.${local.workspace.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = [aws_subnet.aws-endpoints.id]
  security_group_ids = [aws_security_group.aws-endpoint.id]

  # We need a lot of services for SSM, see: https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html#create-vpc-endpoints
  for_each = toset(["secretsmanager", "ssm", "ec2messages", "ec2", "s3", "kms", "logs"])
  tags = {
    Name = "${each.value} Interface VPC Endpoint"
  }
  depends_on = [aws_vpc_endpoint.s3]
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
