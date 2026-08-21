/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template
    
    ⚠️ DO NOT modify this file directly.
    To extend functionality: Reference resources from custom-infrastructure/ directory only.
*/

data "aws_subnet" "private_subnets" {
  for_each = toset(var.private_subnet_ids)
  id       = each.value
}

data "aws_subnet" "public_subnets" {
  for_each = toset(var.public_subnet_ids)
  id       = each.value
}

data "aws_subnet" "eks_private_subnets" {
  for_each = toset(var.eks_private_subnet_ids)
  id       = each.value
}

data "aws_subnet" "eks_public_subnets" {
  for_each = toset(var.eks_public_subnet_ids)
  id       = each.value
}

