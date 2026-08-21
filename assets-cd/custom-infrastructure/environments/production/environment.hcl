/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/custom-infrastructure-integration-template

    ⚠️ DO NOT modify this file directly. to extend it you can add new .hcl file next to it with correct terragrunt configuration.
*/
inputs = {
  aws_account_id          = "021427824859"
  environment             = "production"
  env_code                = "prd"
  remote_state_bucket     = "tfstate-olxeu-data-apps-eu-west-1-021427824859"
  terraform_pipeline_role = "arn:aws:iam::021427824859:role/atlantis"
  dynamodb_lock_table     = "terraform-olxeu-data-core-lock"
}
