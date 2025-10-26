terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
data "aws_caller_identity" "current" {}

module "challenge-repo" {
  source = "../ecr-repo"
  name   = "insider-threat"
}
module "challenge-instance" {
  count  = terraform.workspace == "production" ? 1 : 0
  source = "../challenge-instance"

  ami_id                = var.ami_id
  ec2_key_pair_name     = var.ec2_key_pair_name
  instance_profile_name = aws_iam_instance_profile.insider-threat.name

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
  compose_file          = file("../../round-2/cloud/insider-threat/challenge/docker-compose.yml")
  custom_script         = <<EOF
  export MIDDLEWARES='${var.basic_auth_enabled ? "traefik.http.routers.insider-threat.middlewares=auth" : ""}'
  export KMS_KEY_ID='${aws_kms_key.insider_threat_jwt_key.id}'
  export AWS_REGION=${aws_kms_key.insider_threat_jwt_key.region}
  export ALLOWED_NETWORK='${var.vpc_endpoint_cidr_block}'
  EOF

  dns_names = ["insider-threat"]
}
