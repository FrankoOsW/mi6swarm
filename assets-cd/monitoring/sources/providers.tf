/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template

    To extend this module:
    - Add new .tf files as needed in this directory
    - For new variables: Create custom_vars.tf for definitions
    - Add variable values in environments/<env>/<region>/custom.auto.tfvars
    - Overwrite variables from a tfvars file: tfvars are loaded in alphabetic order so add the same variable in the in environments/<env>/<region>/<name>.override.auto.tfvars that way you will be able to change value of variable provided by service shaper
    - Best practice: Add new variables rather than overriding existing ones
*/

provider "aws" {
  default_tags {
    tags = merge(
      var.default_tags,
    )
  }
}

# GET KEY FOR NEWRELIC PROVIDER
data "aws_secretsmanager_secret" "nr_key" {
  name = "newrelic-credentials"
}

data "aws_secretsmanager_secret_version" "nr_key" {
  secret_id = data.aws_secretsmanager_secret.nr_key.id
}

provider "newrelic" {
  account_id = var.monitoring_account_id
  api_key    = jsondecode(data.aws_secretsmanager_secret_version.nr_key.secret_string)["NEWRELIC_API_KEY"]
}
