resource "aws_secretsmanager_secret" "deepseek-api-token" {
  name_prefix = "deepseek-api-token-${terraform.workspace}"
  tags = {
    Name = "DeepSeek API token"
  }
}
resource "aws_secretsmanager_secret" "openai-api-token" {
  name_prefix = "openai-api-token-${terraform.workspace}"
  tags = {
    Name = "OpenAI API token"
  }
}
