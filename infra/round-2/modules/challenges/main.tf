terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  auth_middleware_data = terraform.workspace == "production" ? "none" : "traefik.http.middlewares.auth.basicauth.users=ctf:$2y$05$HxEyQpPlmnJBlCtejSm1n.QIlqekDHFzYCCDQqCJy0lrxga5vcyPy" # ctf:lunchakuudorohgui
}

data "aws_ssm_parameter" "challenge_ami_amd64" {
  name = "/empasoft-ctf/amis/challenge/amd64/secure-boot"
}

module "aismar" {
  source = "./modules/aismar"
}

module "not_chacha" {
  source = "./modules/not-chacha"
  ami_id = data.aws_ssm_parameter.challenge_ami_amd64.value

  vpc_id                 = var.vpc_id
  subnet_id              = aws_subnet.challenges.id
  subnet_ipv6_cidr_block = aws_subnet.challenges.ipv6_cidr_block
  sg_id                  = aws_security_group.challenge-server.id

  server_index = local.not_chacha_challenge_index

  vpc_endpoint_sg_ids     = var.vpc_endpoint_sg_ids
  vpc_endpoint_cidr_block = var.vpc_endpoint_cidr_block
  instance_connect_sg_ids = var.instance_connect_sg_ids

  dns_zone_id            = var.dns_zone_id
  dns_zone_name          = var.dns_zone_name
  internal_dns_zone_name = var.internal_dns_zone_name

  ec2_key_pair_name = var.ec2_key_pair_name
  assume_policy_ec2 = var.assume_policy_ec2

  letsencrypt_ca_server = var.letsencrypt_ca_server

  basic_auth_enabled   = terraform.workspace != "production"
  auth_middleware_data = local.auth_middleware_data
}

module "insider_threat" {
  source = "./modules/insider-threat"
  ami_id = data.aws_ssm_parameter.challenge_ami_amd64.value

  vpc_id                 = var.vpc_id
  subnet_id              = aws_subnet.challenges.id
  subnet_ipv6_cidr_block = aws_subnet.challenges.ipv6_cidr_block
  sg_id                  = aws_security_group.challenge-server.id

  server_index = local.insider_threat_challenge_index

  vpc_endpoint_sg_ids     = var.vpc_endpoint_sg_ids
  vpc_endpoint_cidr_block = var.vpc_endpoint_cidr_block
  instance_connect_sg_ids = var.instance_connect_sg_ids

  dns_zone_id            = var.dns_zone_id
  dns_zone_name          = var.dns_zone_name
  internal_dns_zone_name = var.internal_dns_zone_name

  ec2_key_pair_name = var.ec2_key_pair_name
  assume_policy_ec2 = var.assume_policy_ec2

  letsencrypt_ca_server = var.letsencrypt_ca_server

  basic_auth_enabled   = terraform.workspace != "production"
  auth_middleware_data = local.auth_middleware_data
}
module "peephole-reloaded" {
  source = "./modules/peephole-reloaded"
  ami_id = data.aws_ssm_parameter.challenge_ami_amd64.value

  vpc_id                 = var.vpc_id
  subnet_id              = aws_subnet.challenges.id
  subnet_ipv6_cidr_block = aws_subnet.challenges.ipv6_cidr_block

  server_index = local.peephole_reloaded_challenge_index

  vpc_endpoint_sg_ids     = var.vpc_endpoint_sg_ids
  vpc_endpoint_cidr_block = var.vpc_endpoint_cidr_block
  instance_connect_sg_ids = var.instance_connect_sg_ids

  monitoring_network_cidr      = var.monitoring_network_cidr
  monitoring_network_cidr_ipv6 = var.monitoring_network_cidr_ipv6

  dns_zone_id            = var.dns_zone_id
  dns_zone_name          = var.dns_zone_name
  internal_dns_zone_name = var.internal_dns_zone_name

  ec2_key_pair_name = var.ec2_key_pair_name
  assume_policy_ec2 = var.assume_policy_ec2

  letsencrypt_ca_server = var.letsencrypt_ca_server

  basic_auth_enabled   = terraform.workspace != "production"
  auth_middleware_data = local.auth_middleware_data
}

module "vin-for-win" {
  source = "./modules/vin-for-win"
  ami_id = data.aws_ssm_parameter.challenge_ami_amd64.value

  vpc_id                 = var.vpc_id
  subnet_id              = aws_subnet.challenges.id
  subnet_ipv6_cidr_block = aws_subnet.challenges.ipv6_cidr_block

  server_index = local.vin_for_win_challenge_index

  vpc_endpoint_sg_ids     = var.vpc_endpoint_sg_ids
  vpc_endpoint_cidr_block = var.vpc_endpoint_cidr_block
  instance_connect_sg_ids = var.instance_connect_sg_ids

  monitoring_network_cidr      = var.monitoring_network_cidr
  monitoring_network_cidr_ipv6 = var.monitoring_network_cidr_ipv6

  dns_zone_id            = var.dns_zone_id
  dns_zone_name          = var.dns_zone_name
  internal_dns_zone_name = var.internal_dns_zone_name

  ec2_key_pair_name = var.ec2_key_pair_name
  assume_policy_ec2 = var.assume_policy_ec2

  letsencrypt_ca_server = var.letsencrypt_ca_server

  basic_auth_enabled   = terraform.workspace != "production"
  auth_middleware_data = local.auth_middleware_data
}

module "who-are-you" {
  source = "./modules/who-are-you"

  ami_id = data.aws_ssm_parameter.challenge_ami_amd64.value

  vpc_id                 = var.vpc_id
  subnet_id              = aws_subnet.challenges.id
  subnet_ipv6_cidr_block = aws_subnet.challenges.ipv6_cidr_block
  sg_id                  = aws_security_group.challenge-server.id

  server_index = local.who_are_you_challenge_index

  vpc_endpoint_sg_ids     = var.vpc_endpoint_sg_ids
  vpc_endpoint_cidr_block = var.vpc_endpoint_cidr_block
  instance_connect_sg_ids = var.instance_connect_sg_ids

  dns_zone_id            = var.dns_zone_id
  dns_zone_name          = var.dns_zone_name
  internal_dns_zone_name = var.internal_dns_zone_name

  ec2_key_pair_name = var.ec2_key_pair_name
  assume_policy_ec2 = var.assume_policy_ec2

  letsencrypt_ca_server = var.letsencrypt_ca_server

  basic_auth_enabled   = terraform.workspace != "production"
  auth_middleware_data = local.auth_middleware_data
}
