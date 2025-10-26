output "ecr_repo_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.repo.arn
}
