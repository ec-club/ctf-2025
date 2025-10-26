resource "aws_subnet" "monitoring-internal" {
  vpc_id          = aws_vpc.ctf.id
  cidr_block      = cidrsubnet(aws_vpc.ctf.cidr_block, 8, 252)
  ipv6_cidr_block = cidrsubnet(aws_vpc.ctf.ipv6_cidr_block, 8, 252)
  tags = {
    Name = "Subnet for metric ingesting services"
  }
}
resource "aws_network_acl" "monitoring-internal" {
  vpc_id = aws_vpc.ctf.id

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = aws_subnet.ctfd.cidr_block
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol        = "tcp"
    rule_no         = 201
    action          = "allow"
    ipv6_cidr_block = aws_subnet.ctfd.ipv6_cidr_block
    from_port       = 80
    to_port         = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = module.challenges.challenges_subnet_cidr
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol        = "tcp"
    rule_no         = 301
    action          = "allow"
    ipv6_cidr_block = module.challenges.challenges_subnet_ipv6_cidr
    from_port       = 80
    to_port         = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = aws_subnet.monitoring.cidr_block
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol        = "tcp"
    rule_no         = 401
    action          = "allow"
    ipv6_cidr_block = aws_subnet.monitoring.ipv6_cidr_block
    from_port       = 80
    to_port         = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = aws_subnet.aws-endpoints.cidr_block
    from_port  = 22
    to_port    = 22
  }
  ingress {
    protocol        = "tcp"
    rule_no         = 501
    action          = "allow"
    ipv6_cidr_block = aws_subnet.aws-endpoints.ipv6_cidr_block
    from_port       = 22
    to_port         = 22
  }
  dynamic "ingress" {
    content {
      protocol   = "tcp"
      rule_no    = 600 + ingress.key
      action     = "allow"
      cidr_block = ingress.value
      from_port  = 1024
      to_port    = 65535
    }
    for_each = { for index, cidr_block in aws_vpc_endpoint.s3.cidr_blocks : 100 * index => cidr_block }
  }

  egress {
    protocol        = "tcp"
    rule_no         = 201
    action          = "allow"
    ipv6_cidr_block = aws_subnet.ctfd.ipv6_cidr_block
    from_port       = 1024
    to_port         = 65535
  }
  egress {
    protocol        = "tcp"
    rule_no         = 301
    action          = "allow"
    ipv6_cidr_block = module.challenges.challenges_subnet_ipv6_cidr
    from_port       = 1024
    to_port         = 65535
  }
  egress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = aws_subnet.monitoring.cidr_block
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    protocol        = "tcp"
    rule_no         = 401
    action          = "allow"
    ipv6_cidr_block = aws_subnet.monitoring.ipv6_cidr_block
    from_port       = 1024
    to_port         = 65535
  }
  egress {
    protocol   = "tcp"
    rule_no    = 500
    action     = "allow"
    cidr_block = aws_subnet.aws-endpoints.cidr_block
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    protocol        = "tcp"
    rule_no         = 501
    action          = "allow"
    ipv6_cidr_block = aws_subnet.aws-endpoints.ipv6_cidr_block
    from_port       = 1024
    to_port         = 65535
  }
  dynamic "egress" {
    content {
      protocol   = "tcp"
      rule_no    = 600 + egress.key
      action     = "allow"
      cidr_block = egress.value
      from_port  = 443
      to_port    = 443
    }
    for_each = { for index, cidr_block in aws_vpc_endpoint.s3.cidr_blocks : 100 * index => cidr_block }
  }

  subnet_ids = [aws_subnet.monitoring-internal.id]
  tags = {
    Name = "Monitoring internal subnet ACL"
  }
}
resource "aws_route_table_association" "monitoring-internal" {
  subnet_id      = aws_subnet.monitoring-internal.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "monitoring-internal" {
  name        = "monitoring-internal-sg"
  description = "Security group for metric ingesting services"
  vpc_id      = aws_vpc.ctf.id

  ingress {
    description     = "Allow SSH traffic from Instance Connect Endpoint SG"
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = aws_ec2_instance_connect_endpoint.private.security_group_ids
  }

  ingress {
    description     = "Allow Prometheus/Loki API access for pushing/pulling metrics"
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.ctfd.id, aws_security_group.grafana.id]
  }
  ingress {
    description      = "Allow Prometheus/Loki API access for pushing/pulling metrics for challenge servers"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = [module.challenges.challenges_subnet_cidr]
    ipv6_cidr_blocks = [module.challenges.challenges_subnet_ipv6_cidr]
  }

  egress {
    protocol         = "ALL"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = [aws_vpc.ctf.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.ctf.ipv6_cidr_block]
  }
  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = aws_vpc_endpoint.s3.cidr_blocks
  }
}

resource "aws_s3_bucket" "loki-storage" {
  bucket = "loki-storage.${aws_route53_zone.ctf.name}"
  tags = {
    Name = "loki-storage"
  }
}
data "aws_iam_policy_document" "loki-access" {
  statement {
    actions = ["s3:ListBucket", "s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.loki-storage.arn}/*",
      "${aws_s3_bucket.loki-storage.arn}",
    ]
  }
}
resource "aws_iam_role" "loki_role" {
  name               = "loki-role-${terraform.workspace}"
  assume_role_policy = data.aws_iam_policy_document.assume_policy_ec2.json
}
resource "aws_iam_role_policy" "loki-s3-access" {
  name   = "loki-s3-access"
  role   = aws_iam_role.loki_role.id
  policy = data.aws_iam_policy_document.loki-access.json
}
resource "aws_iam_instance_profile" "loki_instance_profile" {
  name = "loki-instance-profile-${terraform.workspace}"
  role = aws_iam_role.loki_role.name
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

  primary_network_interface {
    network_interface_id = aws_network_interface.monitoring-internal.id
  }
  root_block_device {
    volume_size = 30
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
export LOKI_DATA_PATH=/mnt/loki
while [ ! -e $DEVICE ]; do sleep 1; done
file -s $DEVICE | grep ext4 || mkfs.ext4 $DEVICE

mkdir -p $LOKI_DATA_PATH
UUID=$(blkid -s UUID -o value $DEVICE)
if ! grep -q "$UUID" /etc/fstab; then
  echo "$DEVICE $LOKI_DATA_PATH ext4 defaults,nofail 0 2" >> /etc/fstab
  mount -a
  systemctl daemon-reload
  chown -R 10001:10001 $LOKI_DATA_PATH
fi

sed -i "s|AWS_REGION|${aws_s3_bucket.loki-storage.region}|g" /opt/app/loki-config.yml
sed -i "s|AWS_BUCKET|${aws_s3_bucket.loki-storage.bucket}|g" /opt/app/loki-config.yml

cd /opt/app
export LOKI_ADDRESS='[${local.loki_address}]:80'
export PROMETHEUS_ADDRESS='[${local.prometheus_address}]:80'
export INTERNAL_DOMAIN='${aws_route53_zone.internal.name}'
docker compose up -d
EOF
  tags = {
    Name = "Monitoring server"
  }
}
resource "aws_ebs_volume" "loki-storage" {
  availability_zone = aws_instance.monitoring.availability_zone
  size              = 15
  encrypted         = true
  tags = {
    Name = "Storage for Loki"
  }
  lifecycle {
    ignore_changes = [availability_zone] # Prevent recreation of volume on instance replacement
  }
}
resource "aws_volume_attachment" "loki-storage" {
  device_name = "sdf" # NVMe device, will be /dev/nvme1n1 inside the instance
  volume_id   = aws_ebs_volume.loki-storage.id
  instance_id = aws_instance.monitoring.id
}

resource "aws_route53_record" "monitoring" {
  zone_id  = aws_route53_zone.internal.zone_id
  name     = each.key
  type     = "AAAA"
  ttl      = 300
  records  = [each.value]
  for_each = { "prometheus" = local.prometheus_address, "loki" = local.loki_address }
}
