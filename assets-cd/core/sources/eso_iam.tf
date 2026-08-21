/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template

    ⚠️ DO NOT modify this file directly.
    To extend functionality: Reference resources from custom-infrastructure/ directory only.
*/

module "eso_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.2.1"

  name                 = "${var.project_name}-eso-${data.aws_region.current.region}"
  use_name_prefix      = false
  description          = "IAM role for ESO."
  trust_condition_test = "StringLike"

  policies = {
    eso_secret_access = aws_iam_policy.eso_secret_access.arn,
  }

  oidc_providers = {
    eks = {
      provider_arn               = var.eks_cluster_oidc
      namespace_service_accounts = ["${var.eks_namespace}:${var.project_name}-eso"]
    }
  }
}

resource "aws_iam_policy" "eso_secret_access" {
  name        = "${var.project_name}-eso"
  description = "Policy for external secrets operator"
  policy      = data.aws_iam_policy_document.eso_secret_access.json
}

data "aws_iam_policy_document" "eso_secret_access" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.project_name}-*",
    ]
  }
  statement {
    actions = [
      "secretsmanager:ListSecrets",
    ]
    resources = [
      "*",
    ]
  }
}
