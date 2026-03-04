data "tls_certificate" "gitlab_com" {
  count = var.create_gitlab_oidc_provider ? 1 : 0
  url   = "https://gitlab.com"
}

resource "aws_iam_openid_connect_provider" "github_oidc_provider" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_openid_connect_provider" "gitlab_oidc_provider" {
  count           = var.create_gitlab_oidc_provider ? 1 : 0
  url             = "https://gitlab.com"
  client_id_list  = ["https://gitlab.com"]
  thumbprint_list = [data.tls_certificate.gitlab_com[0].certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "ci_oidc_assume_role" {
  statement {
    sid     = "GitHubOIDCAssume"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_oidc_provider.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_repository_subject]
    }
  }

  dynamic "statement" {
    for_each = var.create_gitlab_oidc_provider && length(local.gitlab_project_conditions) > 0 ? [1] : []
    content {
      sid     = "GitLabOIDCAssume"
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type        = "Federated"
        identifiers = [aws_iam_openid_connect_provider.gitlab_oidc_provider[0].arn]
      }

      condition {
        test     = "StringEquals"
        variable = "gitlab.com:aud"
        values   = ["https://gitlab.com"]
      }

      condition {
        test     = "StringLike"
        variable = "gitlab.com:sub"
        values   = local.gitlab_project_conditions
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.additional_assume_role_principal_arns) > 0 ? [1] : []
    content {
      sid     = "OptionalDirectAssumeRole"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]

      principals {
        type        = "AWS"
        identifiers = var.additional_assume_role_principal_arns
      }
    }
  }
}

resource "aws_iam_role" "ci_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.ci_oidc_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ci_admin_access_attach" {
  role       = aws_iam_role.ci_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
