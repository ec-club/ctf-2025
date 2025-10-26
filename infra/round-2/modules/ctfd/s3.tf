resource "aws_s3_bucket" "ctfd-uploads" {
  bucket = "uploads.${var.dns_zone_name}"
  tags = {
    Name = "ctfd-uploads"
  }
}
resource "aws_s3_bucket_public_access_block" "ctfd-uploads" {
  bucket                  = aws_s3_bucket.ctfd-uploads.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
data "aws_iam_policy_document" "ctfd-uploads-public-access" {
  statement {
    sid    = "AllowPublicRead"
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.ctfd-uploads.arn}/*",
      "${aws_s3_bucket.ctfd-uploads.arn}",
    ]
    actions = ["S3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
  depends_on = [aws_s3_bucket_public_access_block.ctfd-uploads]
}
resource "aws_s3_bucket_policy" "ctfd-uploads-public-access" {
  bucket     = aws_s3_bucket.ctfd-uploads.id
  policy     = data.aws_iam_policy_document.ctfd-uploads-public-access.json
  depends_on = [aws_s3_bucket_public_access_block.ctfd-uploads]
}
resource "aws_s3_bucket_website_configuration" "ctfd-uploads" {
  bucket = aws_s3_bucket.ctfd-uploads.bucket
  index_document {
    suffix = "index.html"
  }
}

data "aws_iam_policy_document" "ctfd-uploads" {
  statement {
    actions = [
      # For uploads
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.ctfd-uploads.arn}/*",
    ]
  }
  statement {
    actions = [
      # For backups
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.ctfd-uploads.arn]
  }
}

resource "aws_iam_user" "ctfd-s3" {
  name = "ctfd-s3-${terraform.workspace}"
}
resource "aws_iam_user_policy" "ctfd-uploads" {
  name   = "ctfd-uploads"
  user   = aws_iam_user.ctfd-s3.name
  policy = data.aws_iam_policy_document.ctfd-uploads.json
}

resource "aws_iam_access_key" "ctfd-s3" {
  user    = aws_iam_user.ctfd-s3.name
  pgp_key = file("keys/ctfd_public.key")
}
