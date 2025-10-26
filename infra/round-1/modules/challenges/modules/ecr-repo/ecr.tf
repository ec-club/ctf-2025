resource "aws_ecr_repository" "repo" {
  name                 = "challenges/${var.name}"
  image_tag_mutability = "MUTABLE"
}
