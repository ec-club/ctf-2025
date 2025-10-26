terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# See: https://documentation.ubuntu.com/aws/aws-how-to/instances/find-ubuntu-images/
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/arm64/hvm/ebs-gp3/ami-id"
}
data "aws_ssm_parameter" "challenge_ami" {
  name = "/empasoft-ctf/amis/challenge/arm64"
}
data "aws_ssm_parameter" "challenge_ami_amd64" {
  name = "/empasoft-ctf/amis/challenge/amd64/secure-boot"
}

locals {
  disk_investigation_ipv6 = cidrhost(aws_subnet.challenges.ipv6_cidr_block, 10)
  my_little_bucket_ipv6   = cidrhost(aws_subnet.challenges.ipv6_cidr_block, 11)
  himitsu_ipv6            = cidrhost(aws_subnet.challenges.ipv6_cidr_block, 12)
}

module "challenge-repos" {
  source = "./modules/ecr-repo"
  name   = each.key
  for_each = toset([
    "imaginary-challenge",
    "blind-goat",
    "maybe-web",
    "peephole",
    "meme-or-meme",
    "never-debug/challenge",
    "never-debug/watchdog",
    "never-debug/db",
    "provable-randomness",
    "real-reverse-task",
    "not-web",
    "real-reverse-task-reloaded",
  ])
}

module "challenge-servers" {
  source = "./modules/challenge-server"

  vpc_id                 = var.vpc_id
  subnet_id              = aws_subnet.challenges.id
  sg_id                  = aws_security_group.challenge-server.id
  subnet_cidr_block      = var.challenges_subnet_cidr
  subnet_ipv6_cidr_block = var.challenges_subnet_ipv6_cidr

  server_index     = each.value.index
  ami_id           = data.aws_ssm_parameter.challenge_ami_amd64.value
  instance_type    = each.value.instance_type
  instance_profile = aws_iam_instance_profile.challenge-server.name
  key_pair_name    = var.ec2_key_pair_name

  letsencrypt_ca_server  = var.letsencrypt_ca_server
  internal_dns_zone_name = var.internal_dns_zone_name

  dns_zone_id      = var.dns_zone_id
  dns_record_names = each.value.dns_record_names

  hostname     = each.key
  compose_file = each.value.compose_file
  for_each = {
    "real-reverse-task" = {
      index            = 13
      instance_type    = "t3.micro"
      compose_file     = file("../round-1/web/docker-compose.yml")
      dns_record_names = ["real-reverse-task", "real-reverse-task-reloaded"]
    }
    "never-debug" = {
      index            = 14
      instance_type    = "t3.small"
      compose_file     = file("../round-1/reverse/never-debug/docker-compose.yml")
      dns_record_names = ["never-debug"]
    }
    "pwnables" = {
      index            = 15
      instance_type    = "t3.small"
      compose_file     = file("../round-1/pwn/docker-compose.yml")
      dns_record_names = ["peephole", "meme-or-meme"]
    }
    "blind-goat" = {
      index            = 16
      instance_type    = "t3.micro"
      compose_file     = file("../round-1/misc/blind-goat/docker-compose.yml")
      dns_record_names = ["blind-goat"]
    }
    "crypto" = {
      index            = 17
      instance_type    = "t3.small"
      compose_file     = file("../round-1/crypto/docker-compose.yml")
      dns_record_names = ["maybe-web", "not-web"]
    }
    "provable-randomness" = {
      index            = 18
      instance_type    = "t3.small"
      compose_file     = file("../round-1/web/provable-randomness/docker-compose.yml")
      dns_record_names = ["provable-randomness"]
    }
  }
}

module "disk-investigation" {
  source = "./modules/disk-investigation"

  vpc_id                 = var.vpc_id
  subnet_id              = aws_subnet.challenges.id
  sg_id                  = aws_security_group.challenge-server.id
  subnet_cidr_block      = var.challenges_subnet_cidr
  subnet_ipv6_cidr_block = var.challenges_subnet_ipv6_cidr

  ami_id        = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t3.micro"
  key_pair_name = var.ec2_key_pair_name

  assume_policy_ec2 = var.assume_policy_ec2
  instance_profile  = aws_iam_instance_profile.challenge-server.name

  challenge-assets-bucket-arn = aws_s3_bucket.challenge-assets.arn
  challenge-assets-bucket     = aws_s3_bucket.challenge-assets.bucket

  dns_zone_id            = var.dns_zone_id
  internal_dns_zone_name = var.internal_dns_zone_name

  monitoring_ipv6_cidr = var.monitoring_ipv6_cidr
}
