output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "ecr_repo_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.app_repo.name
}

output "ecr_repo_url" {
  description = "The full URI of the ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}
