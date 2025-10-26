resource "aws_subnet" "challenges" {
  vpc_id          = var.vpc_id
  cidr_block      = var.challenges_subnet_cidr
  ipv6_cidr_block = var.challenges_subnet_ipv6_cidr
  tags = {
    Name = "Challenges subnet"
  }
}

resource "aws_security_group" "challenge-server" {
  name   = "Challenge Server SG"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    content {
      protocol         = "tcp"
      from_port        = ingress.key
      to_port          = ingress.key
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    for_each = toset([22, 80, 443, 1337, 2222])
  }
  ingress {
    description      = "Allow HTTP/3 traffic from everywhere"
    protocol         = "udp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
