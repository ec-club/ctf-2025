data "aws_iam_policy_document" "insider-threat" {
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
  statement {
    actions   = ["kms:Sign", "kms:Verify"]
    resources = [aws_kms_key.insider_threat_jwt_key.arn]
  }
}
resource "aws_iam_role" "insider-threat" {
  name               = "insider-threat-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "insider-threat" {
  name   = "insider-threat-policy-${terraform.workspace}"
  role   = aws_iam_role.insider-threat.name
  policy = data.aws_iam_policy_document.insider-threat.json
}
resource "aws_iam_instance_profile" "insider-threat" {
  name = "insider-threat-${terraform.workspace}"
  role = aws_iam_role.insider-threat.name
}
