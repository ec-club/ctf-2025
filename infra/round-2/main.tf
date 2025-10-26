locals {
  # See: https://medium.com/@milescollier/handling-environmental-variables-in-terraform-workspaces-27d0278423df
  env = {
    default = {
      region = "ap-east-1"
    }
    development = {}
    staging     = {}
    production  = {}
  }
  environmentvars = contains(keys(local.env), terraform.workspace) ? terraform.workspace : "default"
  workspace       = merge(local.env["default"], local.env[local.environmentvars])
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket  = "iac.empasoft.tech"
    key     = "tf/state"
    region  = "ap-southeast-1"
    encrypt = true
  }
}
provider "aws" {
  region = local.workspace.region
  default_tags {
    tags = {
      env = terraform.workspace
    }
  }
}

resource "aws_key_pair" "oleg" {
  key_name   = "oleg"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPT3tmhPVG4sFCPuyjDXT6pnBsP0wA0zz7F4RHbHEqBJ"
}

locals {
  letsencrypt_ca_server = terraform.workspace == "production" ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"
}

module "monitoring" {
  source = "./modules/monitoring"

  vpc_id               = aws_vpc.ctf.id
  vpc_ipv4_cidr_blocks = [aws_vpc.ctf.cidr_block, aws_vpc.ctf-singapore.cidr_block]
  vpc_ipv6_cidr_blocks = [aws_vpc.ctf.ipv6_cidr_block, aws_vpc.ctf-singapore.ipv6_cidr_block]

  nat_route_table_id    = aws_route_table.nat_gateway.id
  public_route_table_id = aws_route_table.public.id

  monitoring_subnet_index          = local.monitoring_subnet_index
  monitoring_internal_subnet_index = local.monitoring_internal_subnet_index

  ec2_key_pair_name = aws_key_pair.oleg.key_name
  assume_policy_ec2 = data.aws_iam_policy_document.assume_policy_ec2.json

  instance_connect_endpoint_sg_ids = aws_ec2_instance_connect_endpoint.private.security_group_ids
  s3_cidr_blocks                   = aws_vpc_endpoint.s3.cidr_blocks

  route53_zone_id   = aws_route53_zone.ctf.id
  route53_zone_name = aws_route53_zone.ctf.name

  route53_internal_zone_name         = aws_route53_zone.internal.name
  route53_internal_zone_id           = aws_route53_zone.internal.id
  route53_internal_zone_id_singapore = aws_route53_zone.internal-singapore.id

  letsencrypt_ca_server = local.letsencrypt_ca_server
}
module "ctfd" {
  source = "./modules/ctfd"
  vpc_id = aws_vpc.ctf.id

  ec2_key_pair_name = aws_key_pair.oleg.key_name
  assume_policy_ec2 = data.aws_iam_policy_document.assume_policy_ec2.json

  vpc_ipv4_cidr_block   = aws_vpc.ctf.cidr_block
  vpc_ipv6_cidr_block   = aws_vpc.ctf.ipv6_cidr_block
  public_route_table_id = aws_route_table.public.id

  ctfd_subnet_index            = local.ctfd_subnet_index
  ctfd_internal_subnet_indices = [local.ctfd_internal_subnet_1_index, local.ctfd_internal_subnet_2_index]

  instance_connect_sg_ids = [aws_security_group.aws-ec2-instance-connect-endpoint.id]
  vpc_endpoint_sg_ids     = [aws_security_group.aws-endpoint.id]
  vpc_endpoint_cidr_block = aws_subnet.aws-endpoints.cidr_block
  s3_cidr_blocks          = aws_vpc_endpoint.s3.cidr_blocks

  dns_zone_id            = aws_route53_zone.ctf.id
  dns_zone_name          = aws_route53_zone.ctf.name
  internal_dns_zone_id   = aws_route53_zone.internal.id
  internal_dns_zone_name = aws_route53_zone.internal.name

  letsencrypt_ca_server = local.letsencrypt_ca_server
}

module "challenges" {
  source = "./modules/challenges"
  vpc_id = aws_vpc.ctf.id

  ec2_key_pair_name = aws_key_pair.oleg.key_name
  assume_policy_ec2 = data.aws_iam_policy_document.assume_policy_ec2.json

  vpc_ipv4_cidr_block     = aws_vpc.ctf.cidr_block
  vpc_ipv6_cidr_block     = aws_vpc.ctf.ipv6_cidr_block
  challenges_subnet_index = local.challenges_subnet_index
  public_route_table_id   = aws_route_table.public.id

  monitoring_network_cidr      = module.monitoring.cidr_block
  monitoring_network_cidr_ipv6 = module.monitoring.ipv6_cidr_block

  letsencrypt_ca_server = local.letsencrypt_ca_server

  instance_connect_sg_ids = [aws_security_group.aws-ec2-instance-connect-endpoint.id]
  vpc_endpoint_sg_ids     = [aws_security_group.aws-endpoint.id]
  vpc_endpoint_cidr_block = aws_subnet.aws-endpoints.cidr_block
  s3_cidr_blocks          = aws_vpc_endpoint.s3.cidr_blocks

  dns_zone_id            = aws_route53_zone.ctf.id
  dns_zone_name          = aws_route53_zone.ctf.name
  internal_dns_zone_name = aws_route53_zone.internal.name
}

module "challenges-singapore" {
  source = "./modules/challenges-singapore"
  vpc_id = aws_vpc.ctf-singapore.id

  ec2_key_pair_name = aws_key_pair.oleg.key_name
  assume_policy_ec2 = data.aws_iam_policy_document.assume_policy_ec2.json

  vpc_ipv4_cidr_block     = aws_vpc.ctf-singapore.cidr_block
  vpc_ipv6_cidr_block     = aws_vpc.ctf-singapore.ipv6_cidr_block
  vpc_endpoint_sg_ids     = [aws_security_group.aws-endpoint.id]
  vpc_endpoint_cidr_block = aws_subnet.aws-endpoints.cidr_block
  challenges_subnet_index = local.challenges_subnet_index_singapore

  monitoring_network_cidr      = module.monitoring.cidr_block
  monitoring_network_cidr_ipv6 = module.monitoring.ipv6_cidr_block

  letsencrypt_ca_server = local.letsencrypt_ca_server

  dns_zone_id            = aws_route53_zone.ctf.id
  dns_zone_name          = aws_route53_zone.ctf.name
  internal_dns_zone_name = aws_route53_zone.internal.name
}
