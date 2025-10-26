resource "aws_kms_key" "insider_threat_jwt_key" {
  description              = "ML-DSA key for Insider Threat challenge JWT signing"
  customer_master_key_spec = "ML_DSA_65"
  key_usage                = "SIGN_VERIFY"
  deletion_window_in_days  = 7
  tags = {
    Name = "Insider Threat challenge JWT Key"
  }
}
resource "aws_kms_key_policy" "insider_threat_jwt_key_policy" {
  key_id = aws_kms_key.insider_threat_jwt_key.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action  = ["kms:Sign", "kms:Verify"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = var.vpc_id
          }
        }
      }
    ]
  })
}
