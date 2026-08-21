/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template

    ⚠️ DO NOT modify this file directly. to extend it you can add new .hcl file next to it with correct terragrunt configuration.
*/
inputs = {
  aws_account_id          = "357905889545"
  environment             = "staging"
  env_code                = "stg"
  remote_state_bucket     = "tfstate-olxeu-data-apps-eu-west-1-357905889545"
  terraform_pipeline_role = "arn:aws:iam::357905889545:role/atlantis"
  dynamodb_lock_table     = "terraform-olxeu-data-core-lock"
}
