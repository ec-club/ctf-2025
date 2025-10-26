data "aws_iam_policy_document" "vin-for-win" {
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
      module.challenge-repo["vin-for-win/gateway"].ecr_repo_arn,
      module.challenge-repo["vin-for-win/infotainment"].ecr_repo_arn,
      module.challenge-repo["vin-for-win/manager"].ecr_repo_arn,
    ]
  }
}
resource "aws_iam_role" "vin-for-win" {
  name               = "vin-for-win-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "vin-for-win" {
  name   = "vin-for-win"
  role   = aws_iam_role.vin-for-win.id
  policy = data.aws_iam_policy_document.vin-for-win.json
}
resource "aws_iam_instance_profile" "vin-for-win" {
  name = "vin-for-win-${terraform.workspace}"
  role = aws_iam_role.vin-for-win.name
}
