resource "aws_s3_bucket" "challenge-assets" {
  bucket = "challenge-assets-${terraform.workspace}-empasoft-ctf"
  tags = {
    Name = "Challenge assets"
  }
}
resource "aws_s3_bucket_public_access_block" "challenge-assets" {
  bucket                  = aws_s3_bucket.challenge-assets.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
data "aws_iam_policy_document" "challenge-assets-public-access" {
  statement {
    sid    = "AllowPublicRead"
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.challenge-assets.arn}/*",
      "${aws_s3_bucket.challenge-assets.arn}",
    ]
    actions = ["S3:GetObject"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
  depends_on = [aws_s3_bucket_public_access_block.challenge-assets]
}
resource "aws_s3_bucket_policy" "challenge-assets-public-access" {
  bucket     = aws_s3_bucket.challenge-assets.id
  policy     = data.aws_iam_policy_document.challenge-assets-public-access.json
  depends_on = [aws_s3_bucket_public_access_block.challenge-assets]
}
resource "aws_s3_bucket_website_configuration" "challenge-assets" {
  bucket = aws_s3_bucket.challenge-assets.bucket
  index_document {
    suffix = "index.html"
  }
}
