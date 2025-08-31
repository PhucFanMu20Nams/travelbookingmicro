output "gitlab_ci_role_arn" {
  description = "The ARN of the IAM role for GitLab CI/CD."
  value       = aws_iam_role.gitlab_ci_role.arn
}