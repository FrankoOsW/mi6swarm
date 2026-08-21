/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template
    
    ⚠️ DO NOT modify this file directly.
    To extend functionality: Reference resources from custom-infrastructure/ directory only.
*/

variable "aws_account_id" {
  description = "injected by terragrunt"
  type        = string
}

variable "aws_region" {
  description = "injected by terragrunt"
  type        = string
}

variable "project_name" {
  description = "injected by terragrunt"
  type        = string
}

variable "eks_cluster_oidc" {
  type = string
}

variable "eks_namespace" {
  type    = string
  default = "mi6swarm"
}

variable "eks_service_account" {
  type    = string
  default = "mi6swarm"
}

variable "default_tags" {
  type = map(string)
}

variable "environment" {
  description = "injected by terragrunt"
  type        = string
}