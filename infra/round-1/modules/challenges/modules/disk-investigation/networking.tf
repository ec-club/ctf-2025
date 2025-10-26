resource "aws_security_group" "disk-investigation" {
  name   = "Disk investigation SG"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = 22
    to_port          = 22
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

resource "aws_network_interface" "disk-investigation" {
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.disk-investigation.id]

  enable_primary_ipv6 = true
  ipv6_address_count  = 1
  tags = {
    Name = "Disk Investigation network interface"
  }
}
