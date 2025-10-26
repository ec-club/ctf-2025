resource "aws_secretsmanager_secret" "tg-bot-token" {
  name_prefix = "anarchist-sanctuary-tg-bot-token-${terraform.workspace}"
  tags = {
    Name = "Telegram bot token"
  }
}
