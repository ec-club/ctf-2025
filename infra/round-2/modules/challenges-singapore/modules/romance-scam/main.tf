terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

module "challenge-repo" {
  source   = "../ecr-repo"
  name     = each.key
  for_each = toset(["romance-scam/web", "romance-scam/backend"])
}
module "challenge-instance" {
  count  = terraform.workspace == "production" ? 1 : 0
  source = "../challenge-instance"

  ami_id                = var.ami_id
  ec2_key_pair_name     = var.ec2_key_pair_name
  instance_profile_name = aws_iam_instance_profile.romance-scam.name

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
  compose_file          = file("../../round-2/web/romance-scam/docker-compose.yml")
  custom_script         = <<EOF
  export AWS_REGION='${aws_secretsmanager_secret.tg-bot-token.region}'
  export MIDDLEWARES='${var.basic_auth_enabled ? "traefik.http.routers.romance-scam-frontend.middlewares=auth" : ""}'
  export TG_BOT_TOKEN_SECRET_ID='${aws_secretsmanager_secret.tg-bot-token.id}'

  ${var.ai_endpoint_url != null ? "export AI_MODEL_NAME='${var.ai_model_name}'" : ""}
  ${var.ai_model_name != null ? "export AI_MODEL_NAME='${var.ai_model_name}'" : ""}
  export DEEPSEEK_API_TOKEN_SECRET_ID=${var.deepseek_token_secret_id}
  EOF

  dns_names = ["romance-scam"]
}
