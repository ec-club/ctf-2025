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
data "aws_caller_identity" "current" {}

locals {
  letsencrypt_ca_server = terraform.workspace == "production" ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"
}

module "challenges" {
  source = "./modules/challenges"

  vpc_id                 = aws_vpc.ctf.id
  dns_zone_id            = aws_route53_zone.ctf.id
  internal_dns_zone_name = aws_route53_zone.internal.name

  challenges_subnet_cidr      = cidrsubnet(aws_vpc.ctf.cidr_block, 8, 10)
  challenges_subnet_ipv6_cidr = cidrsubnet(aws_vpc.ctf.ipv6_cidr_block, 8, 10)
  monitoring_ipv6_cidr        = aws_subnet.monitoring-internal.ipv6_cidr_block

  ec2_key_pair_name = aws_key_pair.oleg.key_name
  assume_policy_ec2 = data.aws_iam_policy_document.assume_policy_ec2.json

  letsencrypt_ca_server = local.letsencrypt_ca_server

  github_openid_connect_provider_arn = aws_iam_openid_connect_provider.github.arn
}
