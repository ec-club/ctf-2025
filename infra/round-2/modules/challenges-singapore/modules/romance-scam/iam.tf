data "aws_iam_policy_document" "romance-scam" {
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
      module.challenge-repo["romance-scam/web"].ecr_repo_arn,
      module.challenge-repo["romance-scam/backend"].ecr_repo_arn
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
resource "aws_iam_role" "romance-scam" {
  name               = "romance-scam-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "romance-scam" {
  name   = "romance-scam"
  role   = aws_iam_role.romance-scam.id
  policy = data.aws_iam_policy_document.romance-scam.json
}
resource "aws_iam_instance_profile" "romance-scam" {
  name = "romance-scam-${terraform.workspace}"
  role = aws_iam_role.romance-scam.name
}
