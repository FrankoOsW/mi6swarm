/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template
    
    ⚠️ DO NOT modify this file directly.
    To extend functionality: Reference resources from custom-infrastructure/ directory only.
*/

locals {
  private_subnet_cidrs = tolist([
    for subnet in data.aws_subnet.private_subnets : subnet.cidr_block
  ])

  public_subnet_cidrs = tolist([
    for subnet in data.aws_subnet.public_subnets : subnet.cidr_block
  ])

  eks_private_subnet_cidrs = tolist([
    for subnet in data.aws_subnet.eks_private_subnets : subnet.cidr_block
  ])

  eks_public_subnet_cidrs = tolist([
    for subnet in data.aws_subnet.eks_public_subnets : subnet.cidr_block
  ])
}

