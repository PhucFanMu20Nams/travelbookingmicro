locals {
  github_repository_subject = "repo:${var.github_org}/${var.github_repo}:*"

  gitlab_project_conditions = [
    for project in var.gitlab_projects : "project_path:${project}:ref_type:branch:ref:*"
  ]
}
