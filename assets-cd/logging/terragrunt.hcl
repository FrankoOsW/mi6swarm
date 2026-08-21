/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template

    ⚠️ DO NOT modify this file directly. to extend it you can add new .hcl file next to it with correct terragrunt configuration.
*/
locals {
  # Automatically load region and account level variables
  # Local variables are override
  merged_vars = merge(
    {
      # Global variables
      aws_region          = "eu-west-1"
      dynamodb_lock_table = "terraform-olxeu-k8s-lock"
      project_name        = "mi6swarm"
    },
    read_terragrunt_config("../environment.hcl").inputs,
  )
}
# Configure Atlantis to use the IAM role for the pipeline
iam_role = local.merged_vars.terraform_pipeline_role

# Inject the variables into the Terraform configuration
inputs = local.merged_vars

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    bucket                   = local.merged_vars.remote_state_bucket
    key                      = join("/", [local.merged_vars.environment, local.merged_vars.aws_region, local.merged_vars.project_name, "logging.tfstate"])
    encrypt                  = true
    region                   = local.merged_vars.aws_region
    dynamodb_table           = local.merged_vars.dynamodb_lock_table
    skip_bucket_versioning   = false
    disable_bucket_update    = true
    skip_bucket_root_access  = false
    skip_bucket_enforced_tls = false
  }
}

terraform {
  source = "${find_in_parent_folders()}/../sources"
}