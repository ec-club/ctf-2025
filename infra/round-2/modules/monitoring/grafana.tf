resource "aws_subnet" "monitoring" {
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_ipv4_cidr_blocks[0], 8, var.monitoring_subnet_index)
  ipv6_cidr_block         = cidrsubnet(var.vpc_ipv6_cidr_blocks[0], 8, var.monitoring_subnet_index)
  map_public_ip_on_launch = true
  tags = {
    Name = "Subnet for monitoring services"
  }
}
resource "aws_route_table_association" "monitoring" {
  subnet_id      = aws_subnet.monitoring.id
  route_table_id = var.public_route_table_id
}

resource "aws_security_group" "grafana" {
  name        = "grafana-sg"
  description = "Security group for Grafana"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow SSH traffic from Instance Connect Endpoint SG"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = var.instance_connect_endpoint_sg_ids
  }
  ingress {
    description      = "Allow Grafana access (HTTP)"
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
    description      = "Allow access to Prometheus and Loki"
    protocol         = "TCP"
    from_port        = 80
    to_port          = 80
    ipv6_cidr_blocks = [aws_subnet.monitoring-internal.ipv6_cidr_block]
  }
  dynamic "egress" {
    content {
      description      = "Allow Grafana to download plugins"
      protocol         = "TCP"
      from_port        = egress.key
      to_port          = egress.key
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    for_each = toset([80, 443])
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

  key_name = var.ec2_key_pair_name
  primary_network_interface {
    network_interface_id = aws_network_interface.grafana.id
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
#!/bin/bash -e
DEVICE=/dev/nvme1n1
STORAGE_DATA_PATH=/mnt/storage
while [ ! -e $DEVICE ]; do sleep 1; done
file -s $DEVICE | grep ext4 || mkfs.ext4 $DEVICE

mkdir -p $STORAGE_DATA_PATH
UUID=$(blkid -s UUID -o value $DEVICE)
if ! grep -q "$UUID" /etc/fstab; then
  echo "$DEVICE $STORAGE_DATA_PATH ext4 defaults,nofail 0 2" >> /etc/fstab
  mount -a
  systemctl daemon-reload
  mkdir -p $STORAGE_DATA_PATH/{grafana,alloy,letsencrypt}
  # See: https://hub.docker.com/layers/grafana/grafana/main/images/sha256-bd2fc2dd7cff826f802c59348a02a95f44ac4dec1fc1665a6e03d16f9f4aa47d
  chown -R 472 $STORAGE_DATA_PATH/grafana
fi

export GRAFANA_DATA_PATH=$STORAGE_DATA_PATH/grafana
export ALLOY_DATA_PATH=$STORAGE_DATA_PATH/alloy
export TLS_CERTS_PATH=$STORAGE_DATA_PATH/letsencrypt

cd /opt/app
sed -i "s/MONITORING_DOMAIN/${var.route53_internal_zone_name}/g" /opt/app/config.alloy

export LETSENCRYPT_CA_SERVER='${var.letsencrypt_ca_server}'
export GRAFANA_DOMAIN=grafana.${var.route53_zone_name}
export INTERNAL_DOMAIN=${var.route53_internal_zone_name}
export LOKI_ADDRESS=loki.${var.route53_internal_zone_name}
export PROMETHEUS_ADDRESS=prometheus.${var.route53_internal_zone_name}
docker compose up -d
EOF
  tags = {
    Name = "Grafana server"
  }
}
resource "aws_ebs_volume" "grafana-storage" {
  availability_zone = aws_instance.grafana.availability_zone
  size              = 20
  encrypted         = true
  tags = {
    Name = "Storage for Grafana"
  }
  lifecycle {
    ignore_changes = [availability_zone] # Prevent recreation of volume on instance replacement
  }
}
resource "aws_volume_attachment" "grafana-storage" {
  device_name = "sdf" # NVMe device, will be /dev/nvme1n1 inside the instance
  volume_id   = aws_ebs_volume.grafana-storage.id
  instance_id = aws_instance.grafana.id
}

resource "aws_route53_record" "grafana" {
  zone_id = var.route53_zone_id
  name    = "grafana"
  type    = "A"
  ttl     = 300
  records = [aws_eip.grafana.public_ip]
}
resource "aws_route53_record" "grafana_ipv6" {
  zone_id = var.route53_zone_id
  name    = "grafana"
  type    = "AAAA"
  ttl     = 300
  records = [local.grafana_address]
}
