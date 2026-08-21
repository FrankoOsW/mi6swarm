/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template

    ⚠️ DO NOT modify this file directly.
    To extend functionality: Reference resources from custom-infrastructure/ directory only.

    Example: To attach a policy to this IRSA role, create a new file in custom-infrastructure/sources/:

    resource "aws_iam_policy_attachment" "dynamodb_access" {
      name       = "${var.project_name}-dynamodb-attachment"
      policy_arn = aws_iam_policy.dynamodb_access.arn
      roles      = ["${var.project_name}-irsa-${data.aws_region.current.region}"]
    }

    resource "aws_iam_policy" "dynamodb_access" {
      name        = "${var.project_name}-dynamodb"
      description = "Policy for dynamodb access"
      policy      = data.aws_iam_policy_document.dynamodb_access.json
    }

    data "aws_iam_policy_document" "dynamodb_access" {
      statement {
        actions = [
          "dynamodb:DeleteItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
        ]
        resources = [
          aws_dynamodb_table.overrule_table.arn,
          "${aws_dynamodb_table.overrule_table.arn}/*"
        ]
      }
    }
*/

module "irsa_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.2.1"

  name                 = "${var.project_name}-irsa-${data.aws_region.current.region}"
  use_name_prefix      = false
  description          = "IAM role for the service account."
  trust_condition_test = "StringLike"

  policies = {
  }

  oidc_providers = {
    eks = {
      provider_arn               = var.eks_cluster_oidc
      namespace_service_accounts = ["${var.eks_namespace}:*"]
    }
  }
}

moved {
  from = module.service_iam_role
  to   = module.irsa_iam_role
}
