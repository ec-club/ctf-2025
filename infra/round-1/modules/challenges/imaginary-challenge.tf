data "aws_iam_policy_document" "imaginary-challenge" {
  statement {
    actions   = ["ecr:GetAuthorizationToken", "ecr:DescribeRepositories"]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
    ]
    resources = [module.challenge-repos["imaginary-challenge"].ecr_repo_arn]
  }
}
resource "aws_iam_role" "imaginary-challenge" {
  name = "imaginary-challenge"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.github_openid_connect_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com",
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" : "repo:*-empasoft-ctf/2025-*" # oops
          }
        }
      }
    ]
  })
}
resource "aws_iam_role_policy" "imaginary-challenge" {
  role   = aws_iam_role.imaginary-challenge.id
  policy = data.aws_iam_policy_document.imaginary-challenge.json
}

resource "aws_s3_object" "imaginary-challenge-iam-role" {
  bucket  = aws_s3_bucket.challenge-assets.bucket
  key     = "forensic/imaginary-challenge/iam-role"
  content = aws_iam_role.imaginary-challenge.arn
}
