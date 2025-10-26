resource "aws_s3_bucket" "loki-storage" {
  bucket_prefix = "loki-storage"
  tags = {
    Name = "Loki storage"
  }
}
data "aws_iam_policy_document" "loki-access" {
  statement {
    actions = ["s3:ListBucket", "s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = [
      "${aws_s3_bucket.loki-storage.arn}/*",
      "${aws_s3_bucket.loki-storage.arn}",
    ]
  }
}
resource "aws_iam_role" "loki_role" {
  name               = "loki-role-${terraform.workspace}"
  assume_role_policy = var.assume_policy_ec2
}
resource "aws_iam_role_policy" "loki-s3-access" {
  name_prefix = "loki-s3-access"
  role        = aws_iam_role.loki_role.id
  policy      = data.aws_iam_policy_document.loki-access.json
}
resource "aws_iam_instance_profile" "loki_instance_profile" {
  name = "loki-instance-profile-${terraform.workspace}"
  role = aws_iam_role.loki_role.name
}
