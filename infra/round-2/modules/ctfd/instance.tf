resource "aws_security_group" "ctfd" {
  name        = "ctfd"
  description = "Allow SSH/HTTP/TLS/QUIC inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow SSH traffic from Instance Connect Endpoint SG"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = var.instance_connect_sg_ids
  }
  dynamic "ingress" {
    for_each = toset([80, 443])
    content {
      description      = "Allow inbound traffic on port ${ingress.value}"
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      ipv6_cidr_blocks = ["::/0"]
    }
  }
  ingress {
    description      = "Allow QUIC traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "udp"
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
locals {
  ctfd_private_ip     = cidrhost(aws_subnet.ctfd.cidr_block, 10)
  ctfd_listen_address = cidrhost(aws_subnet.ctfd.ipv6_cidr_block, 10)
}
resource "aws_network_interface" "ctfd" {
  subnet_id           = aws_subnet.ctfd.id
  security_groups     = [aws_security_group.ctfd.id]
  private_ips         = [local.ctfd_private_ip]
  enable_primary_ipv6 = true
  ipv6_addresses      = [local.ctfd_listen_address]
  tags = {
    Name = "CTFd network interface"
  }
}

resource "aws_secretsmanager_secret" "ctfd_secret_key" {
  name_prefix = "empasoft-ctf/${terraform.workspace}/ctfd/secret-key"
}
data "aws_secretsmanager_secret" "ctfd_pgp_key" {
  name = "ctfd-pgp-key"
}
data "aws_iam_policy_document" "ctfd_secret_access" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_db_instance.ctfd.master_user_secret[0].secret_arn, data.aws_secretsmanager_secret.ctfd_pgp_key.arn]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:PutSecretValue",
    ]
    resources = [aws_secretsmanager_secret.ctfd_secret_key.arn]
  }
}
resource "aws_iam_role" "ctfd_instance_role" {
  name               = "ctfd-instance-role-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "ctfd_secret_access" {
  name   = "ctfd-read-secrets"
  role   = aws_iam_role.ctfd_instance_role.id
  policy = data.aws_iam_policy_document.ctfd_secret_access.json
}
resource "aws_iam_instance_profile" "ctfd_instance_profile" {
  name = "ctfd-instance-profile-${terraform.workspace}"
  role = aws_iam_role.ctfd_instance_role.name
}

data "aws_ssm_parameter" "ubuntu_ctfd_ami" {
  name = "/empasoft-ctf/amis/ctfd/arm64"
}
resource "aws_instance" "ctfd" {
  ami           = data.aws_ssm_parameter.ubuntu_ctfd_ami.value
  instance_type = "t4g.medium"

  primary_network_interface {
    network_interface_id = aws_network_interface.ctfd.id
  }
  root_block_device {
    volume_size = 20
  }

  iam_instance_profile = aws_iam_instance_profile.ctfd_instance_profile.name
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

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

  export DOMAIN=${var.dns_zone_name}
  export DB_ENDPOINT=${aws_db_instance.ctfd.endpoint}

  SECRET_KEY_VERSIONS=$(aws secretsmanager list-secret-version-ids --secret-id '${aws_secretsmanager_secret.ctfd_secret_key.arn}' --output json | jq '.Versions | length')
  if [ "$SECRET_KEY_VERSIONS" -eq "0" ]; then
    SECRET_KEY=$(openssl rand -base64 32 | tr -d '=+/')
    aws secretsmanager put-secret-value --secret-id '${aws_secretsmanager_secret.ctfd_secret_key.arn}' --secret-string "{\"SECRET_KEY\":\"$SECRET_KEY\"}"
  fi

  export AWS_S3_ACCESS_KEY_ID=${aws_iam_access_key.ctfd-s3.id}
  export AWS_S3_BUCKET=${aws_s3_bucket.ctfd-uploads.bucket}
  export AWS_REGION=${aws_s3_bucket.ctfd-uploads.region}

  aws secretsmanager get-secret-value --secret-id ctfd-pgp-key --query SecretString --output text > /tmp/ctfd_private.key && gpg --batch --import /tmp/ctfd_private.key; shred /tmp/ctfd_private.key
  ENCRYPTED_AWS_S3_SECRET_ACCESS_KEY='${aws_iam_access_key.ctfd-s3.encrypted_secret}'
  export AWS_S3_SECRET_ACCESS_KEY=$(echo $ENCRYPTED_AWS_S3_SECRET_ACCESS_KEY | base64 -d | gpg --batch --decrypt)

  export SECRET_KEY=$(aws secretsmanager get-secret-value --secret-id '${aws_secretsmanager_secret.ctfd_secret_key.arn}' --query SecretString --output text | jq -r .SECRET_KEY)

  DB_CREDENTIALS=$(aws secretsmanager get-secret-value --secret-id '${aws_db_instance.ctfd.master_user_secret[0].secret_arn}' --query SecretString --output text)
  export DB_USERNAME=$(echo $DB_CREDENTIALS | jq -r .username)
  export DB_PASSWORD=$(echo $DB_CREDENTIALS | jq -r .password)

  export REDIS_ENDPOINT=${aws_elasticache_cluster.ctfd.cache_nodes[0].address}:${aws_elasticache_cluster.ctfd.cache_nodes[0].port}

  export LETSENCRYPT_CA_SERVER='${var.letsencrypt_ca_server}'
  export CTFD_ADDRESS='${local.ctfd_private_ip}:80'
  export CTFD_ADDRESS6='[${local.ctfd_listen_address}]:80'

  export INTERNAL_DOMAIN='${var.internal_dns_zone_name}'
  sed -i "s/MONITORING_DOMAIN/${var.internal_dns_zone_name}/g" /opt/ctfd/config.alloy
	cd /opt/ctfd
  sudo -E docker compose up -d
	EOF
  tags = {
    Name = "CTFd instance"
  }
}
# Use a separate EBS volume for TLS certificates to avoid requesting new ones on every deploy
resource "aws_ebs_volume" "ctfd-tls-certs" {
  availability_zone = aws_instance.ctfd.availability_zone
  size              = 1
  encrypted         = true
  tags = {
    Name = "TLS certificate storage for CTFd"
  }
  lifecycle {
    ignore_changes = [availability_zone] # Prevent recreation of volume on instance replacement
  }
}
resource "aws_volume_attachment" "ctfd-tls-certs" {
  device_name = "sdf" # NVMe device, will be /dev/nvme1n1 inside the instance
  volume_id   = aws_ebs_volume.ctfd-tls-certs.id
  instance_id = aws_instance.ctfd.id
}

resource "aws_route53_record" "ctfd_ipv6" {
  zone_id = var.dns_zone_id
  name    = var.dns_zone_name
  type    = "AAAA"
  ttl     = 300
  records = [local.ctfd_listen_address]
}

resource "aws_route53_record" "ctfd-internal" {
  zone_id = var.internal_dns_zone_id
  name    = var.internal_dns_zone_name
  type    = "A"
  ttl     = 300
  records = [local.ctfd_private_ip]
}
resource "aws_route53_record" "ctfd_ipv6-internal" {
  zone_id = var.internal_dns_zone_id
  name    = var.internal_dns_zone_name
  type    = "AAAA"
  ttl     = 300
  records = [local.ctfd_listen_address]
}
