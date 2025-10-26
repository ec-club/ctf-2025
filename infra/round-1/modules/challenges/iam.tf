data "aws_iam_policy_document" "challenge-server" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
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
    resources = ["*"]
  }
}
resource "aws_iam_role" "challenge-server" {
  name               = "challenge-server-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "challenge-server" {
  name   = "challenge-server-policy"
  role   = aws_iam_role.challenge-server.id
  policy = data.aws_iam_policy_document.challenge-server.json
}
resource "aws_iam_instance_profile" "challenge-server" {
  name = "challenge-server-${terraform.workspace}"
  role = aws_iam_role.challenge-server.name
}
