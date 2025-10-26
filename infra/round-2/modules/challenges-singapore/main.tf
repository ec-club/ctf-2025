provider "aws" {
  region = "ap-southeast-1"
  default_tags {
    tags = {
      env = terraform.workspace
    }
  }
}

locals {
  auth_middleware_data = terraform.workspace == "production" ? "none" : "traefik.http.middlewares.auth.basicauth.users=ctf:$2y$05$HxEyQpPlmnJBlCtejSm1n.QIlqekDHFzYCCDQqCJy0lrxga5vcyPy" # ctf:lunchakuudorohgui
}

resource "aws_key_pair" "oleg" {
  key_name   = "oleg"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPT3tmhPVG4sFCPuyjDXT6pnBsP0wA0zz7F4RHbHEqBJ"
}

data "aws_ssm_parameter" "challenge_ami_amd64" {
  name = "/empasoft-ctf/amis/challenge/amd64/secure-boot"
}

module "romance-scam" {
  source = "./modules/romance-scam"
  ami_id = data.aws_ssm_parameter.challenge_ami_amd64.value

  vpc_id                 = var.vpc_id
  subnet_id              = aws_subnet.challenges.id
  subnet_ipv6_cidr_block = aws_subnet.challenges.ipv6_cidr_block
  sg_id                  = aws_security_group.challenge-server.id

  server_index = local.romance_scam_challenge_index

  deepseek_token_secret_arn = aws_secretsmanager_secret.deepseek-api-token.arn
  deepseek_token_secret_id  = aws_secretsmanager_secret.deepseek-api-token.id

  dns_zone_id            = var.dns_zone_id
  dns_zone_name          = var.dns_zone_name
  internal_dns_zone_name = var.internal_dns_zone_name

  ec2_key_pair_name = var.ec2_key_pair_name
  assume_policy_ec2 = var.assume_policy_ec2

  letsencrypt_ca_server = var.letsencrypt_ca_server

  basic_auth_enabled   = terraform.workspace != "production"
  auth_middleware_data = local.auth_middleware_data
}
module "anarchist-sanctuary" {
  source = "./modules/anarchist-sanctuary"
  ami_id = data.aws_ssm_parameter.challenge_ami_amd64.value

  vpc_id                 = var.vpc_id
  subnet_id              = aws_subnet.challenges.id
  subnet_ipv6_cidr_block = aws_subnet.challenges.ipv6_cidr_block
  sg_id                  = aws_security_group.challenge-server.id

  server_index = local.anarchist_sanctuary_challenge_index

  deepseek_token_secret_arn = aws_secretsmanager_secret.deepseek-api-token.arn
  deepseek_token_secret_id  = aws_secretsmanager_secret.deepseek-api-token.id

  vpc_ipv4_cidr_block          = var.vpc_ipv4_cidr_block
  vpc_ipv6_cidr_block          = var.vpc_ipv6_cidr_block
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
