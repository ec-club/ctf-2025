data "aws_iam_policy_document" "who-are-you" {
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
    resources = [module.challenge-repo.ecr_repo_arn]
  }
}
resource "aws_iam_role" "who-are-you" {
  name               = "who-are-you-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "who-are-you" {
  name   = "who-are-you"
  role   = aws_iam_role.who-are-you.id
  policy = data.aws_iam_policy_document.who-are-you.json
}
resource "aws_iam_instance_profile" "who-are-you" {
  name = "who-are-you-${terraform.workspace}"
  role = aws_iam_role.who-are-you.name
}
