resource "aws_security_group" "cloud-challenge" {
  name   = "Cloud challenge SG"
  vpc_id = var.vpc_id

  ingress {
    description      = "Allow SSH traffic from everywhere"
    protocol         = "tcp"
    from_port        = 22
    to_port          = 22
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
