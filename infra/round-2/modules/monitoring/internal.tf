resource "aws_subnet" "monitoring-internal" {
  vpc_id          = var.vpc_id
  cidr_block      = cidrsubnet(var.vpc_ipv4_cidr_blocks[0], 8, var.monitoring_internal_subnet_index)
  ipv6_cidr_block = cidrsubnet(var.vpc_ipv6_cidr_blocks[0], 8, var.monitoring_internal_subnet_index)
  tags = {
    Name = "Subnet for metric ingesting services"
  }
}
resource "aws_route_table_association" "monitoring-internal" {
  subnet_id      = aws_subnet.monitoring-internal.id
  route_table_id = var.nat_route_table_id
}

resource "aws_security_group" "monitoring-internal" {
  name_prefix = "monitoring-internal-sg"
  description = "Security group for metric ingesting services"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow SSH traffic from Instance Connect Endpoint SG"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = var.instance_connect_endpoint_sg_ids
  }
  ingress {
    description      = "Allow Prometheus/Loki API access"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = var.vpc_ipv4_cidr_blocks
    ipv6_cidr_blocks = var.vpc_ipv6_cidr_blocks
  }

  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.s3_cidr_blocks
  }
}

locals {
  loki_address       = cidrhost(aws_subnet.monitoring-internal.ipv6_cidr_block, 10)
  prometheus_address = cidrhost(aws_subnet.monitoring-internal.ipv6_cidr_block, 11)
}
resource "aws_network_interface" "monitoring-internal" {
  subnet_id       = aws_subnet.monitoring-internal.id
  security_groups = [aws_security_group.monitoring-internal.id]

  private_ips    = [cidrhost(aws_subnet.monitoring-internal.cidr_block, 10)]
  ipv6_addresses = [local.loki_address, local.prometheus_address]
  tags = {
    Name = "Monitoring server network interface"
  }
}

data "aws_ssm_parameter" "monitoring_ami" {
  name = "/empasoft-ctf/amis/monitoring/amd64"
}
resource "aws_instance" "monitoring" {
  ami           = data.aws_ssm_parameter.monitoring_ami.value
  instance_type = "t3.medium" # 2 vCPU, 4 GiB RAM minimal, amd64
  key_name      = var.ec2_key_pair_name

  primary_network_interface {
    network_interface_id = aws_network_interface.monitoring-internal.id
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  iam_instance_profile = aws_iam_instance_profile.loki_instance_profile.name
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 2 # allow IMDSv2 access from within Docker containers
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
  mkdir -p $STORAGE_DATA_PATH/{loki,prometheus,alloy}
  chown -R 10001:10001 $STORAGE_DATA_PATH/loki
  chown -R nobody $STORAGE_DATA_PATH/prometheus
fi

sed -i "s|AWS_REGION|${aws_s3_bucket.loki-storage.region}|g" /opt/app/loki-config.yml
sed -i "s|AWS_BUCKET|${aws_s3_bucket.loki-storage.bucket}|g" /opt/app/loki-config.yml

cd /opt/app
export LOKI_ADDRESS='[${local.loki_address}]:80'
export PROMETHEUS_ADDRESS='[${local.prometheus_address}]:80'
export INTERNAL_DOMAIN='${var.route53_internal_zone_name}'

export ALLOY_DATA_PATH=$STORAGE_DATA_PATH/alloy
export LOKI_DATA_PATH=$STORAGE_DATA_PATH/loki
export PROMETHEUS_DATA_PATH=$STORAGE_DATA_PATH/prometheus
docker compose up -d
EOF
  tags = {
    Name = "Monitoring server"
  }
}
resource "aws_ebs_volume" "monitoring-storage" {
  availability_zone = aws_instance.monitoring.availability_zone
  size              = 30
  encrypted         = true
  tags = {
    Name = "Storage for monitoring services"
  }
  lifecycle {
    ignore_changes = [availability_zone] # Prevent recreation of volume on instance replacement
  }
}
resource "aws_volume_attachment" "monitoring-storage" {
  device_name = "sdf" # NVMe device, will be /dev/nvme1n1 inside the instance
  volume_id   = aws_ebs_volume.monitoring-storage.id
  instance_id = aws_instance.monitoring.id
}

resource "aws_route53_record" "prometheus" {
  zone_id = var.route53_internal_zone_id
  name    = "prometheus"
  type    = "AAAA"
  ttl     = 300
  records = [local.prometheus_address]
}
resource "aws_route53_record" "prometheus-singapore" {
  zone_id = var.route53_internal_zone_id_singapore
  name    = "prometheus"
  type    = "AAAA"
  ttl     = 300
  records = [local.prometheus_address]
}
resource "aws_route53_record" "loki" {
  zone_id = var.route53_internal_zone_id
  name    = "loki"
  type    = "AAAA"
  ttl     = 300
  records = [local.loki_address]
}
resource "aws_route53_record" "monitoring-singapore" {
  zone_id = var.route53_internal_zone_id_singapore
  name    = "loki"
  type    = "AAAA"
  ttl     = 300
  records = [local.loki_address]
}
