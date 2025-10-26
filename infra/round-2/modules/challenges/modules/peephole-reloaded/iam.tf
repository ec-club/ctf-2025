data "aws_iam_policy_document" "peephole-reloaded" {
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
resource "aws_iam_role" "peephole-reloaded" {
  name               = "peephole-reloaded-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "peephole-reloaded" {
  name   = "peephole-reloaded"
  role   = aws_iam_role.peephole-reloaded.id
  policy = data.aws_iam_policy_document.peephole-reloaded.json
}
resource "aws_iam_instance_profile" "peephole-reloaded" {
  name = "peephole-reloaded-${terraform.workspace}"
  role = aws_iam_role.peephole-reloaded.name
}
