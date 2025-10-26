data "aws_iam_policy_document" "anarchist-sanctuary" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
    ]
    resources = [
      module.challenge-repo["anarchist-sanctuary/web"].ecr_repo_arn,
      module.challenge-repo["anarchist-sanctuary/bot"].ecr_repo_arn,
      module.challenge-repo["anarchist-sanctuary/chatbot"].ecr_repo_arn
    ]
  }
  statement {
    actions = [
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [var.deepseek_token_secret_arn, aws_secretsmanager_secret.tg-bot-token.arn]
  }
}
resource "aws_iam_role" "anarchist-sanctuary" {
  name               = "anarchist-sanctuary-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "anarchist-sanctuary" {
  name   = "anarchist-sanctuary"
  role   = aws_iam_role.anarchist-sanctuary.id
  policy = data.aws_iam_policy_document.anarchist-sanctuary.json
}
resource "aws_iam_instance_profile" "anarchist-sanctuary" {
  name = "anarchist-sanctuary-${terraform.workspace}"
  role = aws_iam_role.anarchist-sanctuary.name
}
