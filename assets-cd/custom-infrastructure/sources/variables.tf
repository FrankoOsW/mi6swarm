/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/custom-infrastructure-integration-template

    To extend this module:
    - Add new .tf files as needed in this directory
    - For new variables: Create custom_vars.tf for definitions
    - Add variable values in environments/<env>/<region>/custom.auto.tfvars
    - Overwrite variables from a tfvars file: tfvars are loaded in alphabetic order so add the same variable in the in environments/<env>/<region>/<name>.override.auto.tfvars that way you will be able to change value of variable provided by service shaper
    - Best practice: Add new variables rather than overriding existing ones
*/

variable "aws_account_id" {
  description = "injected by terragrunt"
  type        = string
}

variable "aws_region" {
  description = "injected by terragrunt"
  type        = string
}

variable "dynamodb_lock_table" {
  description = "injected by terragrunt"
  type        = string
}

variable "env_code" {
  description = "injected by terragrunt"
  type        = string
}

variable "environment" {
  description = "injected by terragrunt"
  type        = string
}

variable "project_name" {
  description = "injected by terragrunt"
  type        = string
}

variable "terraform_pipeline_role" {
  description = "injected by terragrunt"
  type        = string
}

variable "default_tags" {
  type = map(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "eks_private_subnet_ids" {
  type = list(string)
}

variable "eks_public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "eks_cluster_oidc" {
  type = string
}
