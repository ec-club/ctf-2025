terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

module "challenge-repo" {
  source = "../ecr-repo"
  name   = "not-chacha"
}

module "challenge-instance" {
  source = "../challenge-instance"

  ami_id                = var.ami_id
  ec2_key_pair_name     = var.ec2_key_pair_name
  instance_profile_name = aws_iam_instance_profile.not-chacha.name

  vpc_id                 = var.vpc_id
  subnet_id              = var.subnet_id
  subnet_ipv6_cidr_block = var.subnet_ipv6_cidr_block
  sg_id                  = var.sg_id

  dns_zone_id            = var.dns_zone_id
  dns_zone_name          = var.dns_zone_name
  internal_dns_zone_name = var.internal_dns_zone_name

  server_index         = var.server_index
  auth_middleware_data = var.auth_middleware_data

  letsencrypt_ca_server = var.letsencrypt_ca_server
  compose_file          = file("../../round-2/crypto/not-chacha/docker-compose.yml")

  dns_names = ["not-chacha"]
}
