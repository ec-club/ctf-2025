resource "aws_s3_bucket" "challenge" {
  bucket = "aismar"
}
resource "aws_s3_bucket_public_access_block" "challenge" {
  bucket                  = aws_s3_bucket.challenge.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
data "aws_iam_policy_document" "challenge-public-access" {
  statement {
    sid    = "AllowPublicRead"
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.challenge.arn}/*",
      "${aws_s3_bucket.challenge.arn}",
    ]
    actions = ["S3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
  depends_on = [aws_s3_bucket_public_access_block.challenge]
}
resource "aws_s3_bucket_policy" "challenge-public-access" {
  bucket     = aws_s3_bucket.challenge.id
  policy     = data.aws_iam_policy_document.challenge-public-access.json
  depends_on = [aws_s3_bucket_public_access_block.challenge]
}
resource "aws_s3_bucket_website_configuration" "challenge" {
  bucket = aws_s3_bucket.challenge.bucket
  index_document {
    suffix = "index.html"
  }
}
