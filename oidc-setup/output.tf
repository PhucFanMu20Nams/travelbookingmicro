output "github_ci_role_arn" {
  description = "The ARN of the IAM role for GitHub Actions OIDC."
  value       = aws_iam_role.ci_role.arn
}

output "gitlab_ci_role_arn" {
  description = "Compatibility output name. Returns the same CI role ARN."
  value       = aws_iam_role.ci_role.arn
}
