resource "aws_subnet" "challenges" {
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_ipv4_cidr_block, 8, var.challenges_subnet_index)
  ipv6_cidr_block         = cidrsubnet(var.vpc_ipv6_cidr_block, 8, var.challenges_subnet_index)
  map_public_ip_on_launch = true
  tags = {
    Name = "Challenges subnet"
  }
}

locals {
  romance_scam_challenge_index        = 10
  anarchist_sanctuary_challenge_index = 11
}

resource "aws_security_group" "challenge-server" {
  name   = "Challenge Server SG"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = 22
    to_port          = 22
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  dynamic "ingress" {
    content {
      protocol         = "tcp"
      from_port        = ingress.key
      to_port          = ingress.key
      ipv6_cidr_blocks = ["::/0"]
    }
    for_each = toset([80, 443])
  }
  ingress {
    description      = "Allow HTTP/3 traffic from everywhere"
    protocol         = "udp"
    from_port        = 443
    to_port          = 443
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "ALL"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
