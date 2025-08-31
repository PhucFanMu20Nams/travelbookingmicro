data "tls_certificate" "gitlab_com" {
  url = "https://gitlab.com"
}

resource "aws_iam_openid_connect_provider" "gitlab_oidc_provider" {
  url             = "https://gitlab.com"
  client_id_list  = ["https://gitlab.com"]
  thumbprint_list = [data.tls_certificate.gitlab_com.certificates[0].sha1_fingerprint]
}

data "aws_iam_policy_document" "gitlab_oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.gitlab_oidc_provider.arn]
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

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::<AccountID>:user/acadev"]
    }
  }
}

# Create the IAM role itself using the trust policy defined above.
resource "aws_iam_role" "gitlab_ci_role" {
  name               = "GitLab-OIDC-Role"
  assume_role_policy = data.aws_iam_policy_document.gitlab_oidc_assume_role.json
}

resource "aws_iam_role_policy_attachment" "gitlab_admin_access_attach" {
  role       = aws_iam_role.gitlab_ci_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}