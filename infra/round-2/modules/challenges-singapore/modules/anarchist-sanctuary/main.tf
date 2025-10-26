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
  for_each = toset(["anarchist-sanctuary/web", "anarchist-sanctuary/bot", "anarchist-sanctuary/chatbot"])
}

module "challenge-instance" {
  source = "../challenge-instance"

  ami_id                = var.ami_id
  instance_type         = "t3.small"
  ec2_key_pair_name     = var.ec2_key_pair_name
  instance_profile_name = aws_iam_instance_profile.anarchist-sanctuary.name

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
  compose_file          = file("../../round-2/web/anarchist-sanctuary/docker-compose.yml")
  custom_script         = <<EOF
  export AWS_REGION='${aws_secretsmanager_secret.tg-bot-token.region}'
  export MIDDLEWARES='${var.basic_auth_enabled ? "traefik.http.routers.anarchist-sanctuary.middlewares=auth" : ""}'
  export TG_BOT_TOKEN_SECRET_ID='${aws_secretsmanager_secret.tg-bot-token.id}'

  export DEEPSEEK_API_TOKEN_SECRET_ID=${var.deepseek_token_secret_id}
  ${var.ai_model_name != null ? "export AI_MODEL_NAME='${var.ai_model_name}'" : ""}
  ${var.ai_endpoint_url != null ? "export AI_ENDPOINT_URL='${var.ai_endpoint_url}'" : ""}

  if [ ! -f /opt/app/secret-key ]; then
    openssl rand -base64 32 | tr -d '=+/' > /opt/app/app-key
    chmod 600 /opt/app/app-key
  fi
  export APP_SECRET=$(cat /opt/app/app-key)
  EOF

  dns_names = ["anarchist-sanctuary"]
}
