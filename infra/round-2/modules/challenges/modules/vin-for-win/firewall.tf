resource "aws_security_group" "vin-for-win" {
  name   = "VIN for win challenge security group"
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

  ingress {
    description      = "Allow challenge traffic"
    protocol         = "tcp"
    from_port        = 20000
    to_port          = 30000
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = [var.monitoring_network_cidr]
    ipv6_cidr_blocks = [var.monitoring_network_cidr_ipv6]
  }
  egress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = var.vpc_endpoint_sg_ids
  }
  egress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
