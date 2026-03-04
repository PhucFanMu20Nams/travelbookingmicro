variable "region" {
  description = "AWS region for IAM resources"
  type        = string
  default     = "eu-west-2"
}

variable "github_org" {
  description = "GitHub organization or username hosting the application repository"
  type        = string
}

variable "github_repo" {
  description = "Application repository name in GitHub"
  type        = string
  default     = "online-boutique"
}

variable "role_name" {
  description = "IAM role name assumed by CI via OIDC"
  type        = string
  default     = "GitHub-Actions-OIDC-Role"
}

variable "create_gitlab_oidc_provider" {
  description = "Set true only if you still need legacy GitLab OIDC trust during migration"
  type        = bool
  default     = false
}

variable "gitlab_projects" {
  description = "List of GitLab projects in <group>/<project> form allowed to assume this role when legacy GitLab OIDC is enabled"
  type        = list(string)
  default     = []
}

variable "additional_assume_role_principal_arns" {
  description = "Optional AWS principal ARNs allowed to call sts:AssumeRole directly (for emergency/admin access)"
  type        = list(string)
  default     = []
}
