locals {
  ipv6_address = cidrhost(var.subnet_ipv6_cidr_block, var.server_index)
}

resource "aws_network_interface" "challenge-server" {
  subnet_id       = var.subnet_id
  security_groups = [var.sg_id]

  enable_primary_ipv6 = true
  ipv6_addresses      = [local.ipv6_address]
  tags = {
    Name = "Challenge server network interface"
  }
}

resource "aws_instance" "challenge-server" {
  ami           = var.ami_id
  instance_type = var.instance_type

  primary_network_interface {
    network_interface_id = aws_network_interface.challenge-server.id
  }
  root_block_device {
    volume_size = 30
  }

  iam_instance_profile = var.instance_profile_name
  metadata_options {
    http_tokens                 = "required"
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "enabled"
    http_put_response_hop_limit = 2
  }

  key_name  = var.ec2_key_pair_name
  user_data = <<-EOF
#!/bin/bash -e
DEVICE=/dev/nvme1n1
MOUNT_POINT=/mnt/tls-certs
while [ ! -e $DEVICE ]; do sleep 1; done
file -s $DEVICE | grep ext4 || mkfs.ext4 $DEVICE

mkdir -p $MOUNT_POINT
UUID=$(blkid -s UUID -o value $DEVICE)
if ! grep -q "$UUID" /etc/fstab; then
	echo "$DEVICE $MOUNT_POINT ext4 defaults,nofail 0 2" >> /etc/fstab
	mount -a
	systemctl daemon-reload
fi

export TLS_CERTS_PATH=$MOUNT_POINT
export LETSENCRYPT_CA_SERVER='${var.letsencrypt_ca_server}'

export INTERNAL_DOMAIN='${var.internal_dns_zone_name}'
sed -i "s/MONITORING_DOMAIN/${var.internal_dns_zone_name}/g" /opt/traefik/config.alloy

export HOSTNAME=${var.dns_names[0]}.ctf
cd /opt/traefik && docker compose up -d

mkdir -p /opt/app
cat << EOT > /opt/app/docker-compose.yml
${replace(replace(var.compose_file, "`", "\\`"), "$", "\\$")}
EOT

export CTF_DOMAIN_NAME='${var.dns_zone_name}'
${var.custom_script}
export AUTH_MIDDLEWARE_DATA='${var.auth_middleware_data}'
cd /opt/app && docker compose up -d
	EOF

  tags = {
    Name = "Challenge server"
  }
}
# Use a separate EBS volume for TLS certificates to avoid requesting new ones on every deploy
resource "aws_ebs_volume" "challenge-tls-certs" {
  availability_zone = aws_instance.challenge-server.availability_zone
  size              = 1
  encrypted         = true
  tags = {
    Name = "TLS certificate storage for Insider Threat challenge server"
  }
  lifecycle {
    ignore_changes = [availability_zone] # Prevent recreation of volume on instance replacement
  }
}
resource "aws_volume_attachment" "challenge-tls-certs" {
  device_name = "sdf" # NVMe device, will be /dev/nvme1n1 inside the instance
  volume_id   = aws_ebs_volume.challenge-tls-certs.id
  instance_id = aws_instance.challenge-server.id
}

resource "aws_route53_record" "challenge-server_ipv6" {
  zone_id  = var.dns_zone_id
  name     = each.key
  type     = "AAAA"
  ttl      = 300
  records  = aws_network_interface.challenge-server.ipv6_addresses
  for_each = toset(var.dns_names)
}
