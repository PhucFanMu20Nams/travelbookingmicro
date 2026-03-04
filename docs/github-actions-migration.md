# GitHub Actions Migration Notes

## One-time Terraform state migration

Run after merging backend `s3` changes and before first GitHub Actions apply:

```bash
cd eksinfra
terraform init -migrate-state

cd ../oidc-setup
terraform init -migrate-state
```

The caller must have permission to read existing GitLab HTTP state and write to:
- S3 bucket: `online-boutique-terraform-state`
- DynamoDB lock table: `online-boutique-terraform-locks`

## OIDC setup required variables

`oidc-setup` Terraform now requires:
- `github_org`
- `github_repo` (default `online-boutique`)

Optional:
- `create_gitlab_oidc_provider` (default `false`)
- `gitlab_projects` (legacy transition only)
- `additional_assume_role_principal_arns` (break-glass admin assume-role ARNs)

## gitops-helm repository workflow

This repo intentionally does not contain active `helm-deploy.yml`.
Use this template in the separate `gitops-helm` repository:
- `docs/gitops-helm/helm-deploy.yml`
