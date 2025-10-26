resource "aws_subnet" "monitoring" {
  vpc_id                  = aws_vpc.ctf.id
  cidr_block              = cidrsubnet(aws_vpc.ctf.cidr_block, 8, 253)
  ipv6_cidr_block         = cidrsubnet(aws_vpc.ctf.ipv6_cidr_block, 8, 253)
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet for monitoring services"
  }
}

resource "aws_security_group" "grafana" {
  name        = "grafana-sg"
  description = "Security group for Grafana"
  vpc_id      = aws_vpc.ctf.id

  ingress {
    description     = "Allow SSH traffic from Instance Connect Endpoint SG"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = aws_ec2_instance_connect_endpoint.private.security_group_ids
  }

  ingress {
    description      = "Allow Grafana access"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "Allow Grafana access (HTTPS)"
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "Allow Grafana access (QUIC)"
    protocol         = "udp"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "ALL"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = [aws_vpc.ctf.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.ctf.ipv6_cidr_block]
  }
  egress {
    protocol         = "TCP"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    protocol         = "TCP"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    protocol         = "UDP"
    from_port        = 443
    to_port          = 443
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

locals {
  grafana_address = cidrhost(aws_subnet.monitoring.ipv6_cidr_block, 10)
}
resource "aws_network_interface" "grafana" {
  subnet_id       = aws_subnet.monitoring.id
  security_groups = [aws_security_group.grafana.id]

  private_ips    = [cidrhost(aws_subnet.monitoring.cidr_block, 10)]
  ipv6_addresses = [local.grafana_address]
  tags = {
    Name = "Monitoring network interface"
  }
}
resource "aws_eip" "grafana" {
  domain            = "vpc"
  network_interface = aws_network_interface.grafana.id
  tags = {
    Name = "Grafana public IP"
  }
}

data "aws_ssm_parameter" "grafana_ami" {
  name = "/empasoft-ctf/amis/grafana/arm64"
}
resource "aws_instance" "grafana" {
  ami           = data.aws_ssm_parameter.grafana_ami.value
  instance_type = "t4g.micro"

  primary_network_interface {
    network_interface_id = aws_network_interface.grafana.id
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
#!/bin/bash -e
sed -i "s/MONITORING_DOMAIN/${aws_route53_zone.internal.name}/g" /opt/app/config.alloy

cd /opt/app
export LETSENCRYPT_CA_SERVER='${local.letsencrypt_ca_server}'
export GRAFANA_DOMAIN=grafana.${aws_route53_zone.ctf.name}
export INTERNAL_DOMAIN=${aws_route53_zone.internal.name}
export LOKI_ADDRESS=loki.${aws_route53_zone.internal.name}
export PROMETHEUS_ADDRESS=prometheus.${aws_route53_zone.internal.name}
docker compose up -d
EOF
  tags = {
    Name = "Grafana server"
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = aws_route53_zone.ctf.zone_id
  name    = "grafana"
  type    = "A"
  ttl     = 300
  records = [aws_eip.grafana.public_ip]
}
resource "aws_route53_record" "grafana_ipv6" {
  zone_id = aws_route53_zone.ctf.zone_id
  name    = "grafana"
  type    = "AAAA"
  ttl     = 300
  records = [local.grafana_address]
}
resource "aws_route53_record" "grafana-internal" {
  zone_id = aws_route53_zone.ctf-internal.zone_id
  name    = "grafana"
  type    = "A"
  ttl     = 300
  records = [aws_network_interface.grafana.private_ip]
}
resource "aws_route53_record" "grafana_ipv6-internal" {
  zone_id = aws_route53_zone.ctf-internal.zone_id
  name    = "grafana"
  type    = "AAAA"
  ttl     = 300
  records = [local.grafana_address]
}
