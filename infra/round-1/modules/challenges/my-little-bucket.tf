resource "aws_s3_bucket" "my-little-bucket" {
  bucket_prefix = "my-little-bucket"
  tags = {
    Name = "My Little Bucket challenge bucket"
  }
}
resource "aws_s3_object" "my-little-bucket-flag" {
  bucket  = aws_s3_bucket.my-little-bucket.id
  key     = "flag.txt"
  content = "ECTF{my-jtb9TiTxpLHxoOdZ5WiENZBmJRLgJ60N1gWkdzhhek-little-bucket-TqngGt5aH6SKibFPYpWkMxYLf1R6Z2f8RKtvbyegYg}"
}
data "aws_iam_policy_document" "my-little-bucket" {
  statement {
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.challenge-assets.arn}/cloud/my-little-bucket/id_ed25519",
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:if-none-match"
      values   = ["*"]
    }
  }
  statement {
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }
  statement {
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.my-little-bucket.arn}"]
  }
  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.my-little-bucket.arn}/*",
    ]
  }
}
resource "aws_iam_role" "my-little-bucket" {
  name               = "my-little-bucket-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "my-little-bucket" {
  name   = "my-little-bucket-policy"
  role   = aws_iam_role.my-little-bucket.id
  policy = data.aws_iam_policy_document.my-little-bucket.json
}
resource "aws_iam_instance_profile" "my-little-bucket" {
  name = "my-little-bucket-${terraform.workspace}"
  role = aws_iam_role.my-little-bucket.name
}

resource "aws_instance" "my-little-bucket" {
  ami = data.aws_ssm_parameter.challenge_ami.value

  instance_type   = "t4g.nano"
  subnet_id       = aws_subnet.challenges.id
  ipv6_addresses  = [local.my_little_bucket_ipv6]
  security_groups = [aws_security_group.cloud-challenge.id]

  iam_instance_profile = aws_iam_instance_profile.my-little-bucket.name
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
aws s3api put-object --bucket ${aws_s3_bucket.challenge-assets.bucket} --key cloud/my-little-bucket/id_ed25519 --body /home/challenge/.ssh/id_ed25519 --if-none-match '*'
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
    Name = "My Little bucket challenge server"
  }
}

resource "aws_route53_record" "my-little-bucket" {
  zone_id = var.dns_zone_id
  name    = "my-little-bucket"
  type    = "AAAA"
  ttl     = 300
  records = [local.my_little_bucket_ipv6]
}
