locals {
  gitlab_projects = [
    "<gitlab-repo-username>/<Repo-Name>",
    "<gitlab-repo-username>/<Repo-Name>"
  ]
  gitlab_project_conditions = [
    for project in local.gitlab_projects : "project_path:${project}:ref_type:branch:ref:*"
  ]
}