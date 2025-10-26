data "aws_iam_policy_document" "not-chacha" {
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
resource "aws_iam_role" "not-chacha" {
  name               = "not-chacha-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "not-chacha" {
  name   = "not-chacha"
  role   = aws_iam_role.not-chacha.id
  policy = data.aws_iam_policy_document.not-chacha.json
}
resource "aws_iam_instance_profile" "not-chacha" {
  name = "not-chacha-${terraform.workspace}"
  role = aws_iam_role.not-chacha.name
}
