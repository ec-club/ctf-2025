resource "aws_secretsmanager_secret" "himitsu" {
  name_prefix = "himitsu-${terraform.workspace}"
  tags = {
    Name = "Himitsu challenge flag"
  }
}
resource "aws_secretsmanager_secret_version" "himitsu-flag" {
  secret_id     = aws_secretsmanager_secret.himitsu.id
  secret_string = "ECTF{v3ry-s3cr3t-qP9AxVErTJvPKA7PrAYvst1lBfW7fHzv5iIkxemyOlk-st00r@g3-G7dkh2Dt5gCfEziu4vGn3Kf5uKGCazgaUnCysOiac4}"
}
data "aws_iam_policy_document" "himitsu" {
  statement {
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.challenge-assets.arn}/cloud/himitsu/id_ed25519",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:if-none-match"
      values   = ["*"]
    }
  }
  statement {
    actions   = ["sts:GetCallerIdentity", "secretsmanager:ListSecrets"]
    resources = ["*"]
  }
  statement {
    actions = [
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.himitsu.arn]
  }
}
resource "aws_iam_role" "himitsu" {
  name               = "himitsu-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "himitsu" {
  name   = "himitsu"
  role   = aws_iam_role.himitsu.id
  policy = data.aws_iam_policy_document.himitsu.json
}
resource "aws_iam_instance_profile" "himitsu" {
  name = "himitsu-${terraform.workspace}"
  role = aws_iam_role.himitsu.name
}

resource "aws_instance" "himitsu" {
  ami = data.aws_ssm_parameter.challenge_ami.value

  instance_type   = "t4g.nano"
  subnet_id       = aws_subnet.challenges.id
  ipv6_addresses  = [local.himitsu_ipv6]
  security_groups = [aws_security_group.cloud-challenge.id]

  iam_instance_profile = aws_iam_instance_profile.himitsu.name
  metadata_options {
    http_tokens        = "required"
    http_endpoint      = "enabled"
    http_protocol_ipv6 = "enabled"
  }

  key_name  = var.ec2_key_pair_name
  user_data = <<-EOF
#!/bin/bash -e
useradd -s /sbin/nologin challenge
mkdir -p /home/challenge/.ssh
ssh-keygen -t ed25519 -f /home/challenge/.ssh/id_ed25519 -N "" -q
aws s3api put-object --bucket ${aws_s3_bucket.challenge-assets.bucket} --key cloud/himitsu/id_ed25519 --body /home/challenge/.ssh/id_ed25519 --if-none-match '*'
shred -u /home/challenge/.ssh/id_ed25519

echo 'command="/sbin/nologin"' $(cat /home/challenge/.ssh/id_ed25519.pub) > /home/challenge/.ssh/authorized_keys
rm /home/challenge/.ssh/id_ed25519.pub
chmod 600 /home/challenge/.ssh/authorized_keys
chown -R challenge:challenge /home/challenge/.ssh
chattr +i /home/challenge/.ssh
chattr +i /home/challenge/.ssh/authorized_keys
	EOF

  lifecycle {
    ignore_changes = [security_groups]
  }
  tags = {
    Name = "Himitsu challenge server"
  }
}

resource "aws_route53_record" "himitsu" {
  zone_id = var.dns_zone_id
  name    = "himitsu"
  type    = "AAAA"
  ttl     = 300
  records = [local.himitsu_ipv6]
}
