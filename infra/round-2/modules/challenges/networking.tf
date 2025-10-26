resource "aws_subnet" "challenges" {
  vpc_id          = var.vpc_id
  cidr_block      = cidrsubnet(var.vpc_ipv4_cidr_block, 8, var.challenges_subnet_index)
  ipv6_cidr_block = cidrsubnet(var.vpc_ipv6_cidr_block, 8, var.challenges_subnet_index)
  tags = {
    Name = "Challenges subnet"
  }
}
resource "aws_route_table_association" "challenges" {
  subnet_id      = aws_subnet.challenges.id
  route_table_id = var.public_route_table_id
}

locals {
  insider_threat_challenge_index      = 10
  romance_scam_challenge_index        = 11
  vin_for_win_challenge_index         = 12
  anarchist_sanctuary_challenge_index = 13
  peephole_reloaded_challenge_index   = 14
  not_chacha_challenge_index          = 15
  who_are_you_challenge_index         = 16
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
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
