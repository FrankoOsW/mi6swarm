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

module "o11y_fundamentals_myservice" {
  source = "git::git@git.naspersclassifieds.com:olxeu/core-tech/core-tech-observability/tf-modules/tf-observability-essentials?ref=v1.2.5"

  service_uuid  = var.service_uid
  service_name  = var.service_name
  nr_account_id = var.monitoring_account_id

  kubernetes_cluster_name   = var.kubernetes_cluster_name
  kubernetes_namespace_name = var.kubernetes_namespace_name
  kubernetes_ingress_name   = var.kubernetes_ingress_name

  alert_policy_id = module.workflows.policy_ids[var.service_name]

  pages = var.pages

  # ALB
  alb_requests_alert = var.alb_requests_alert
  alb_errors_alert   = var.alb_errors_alert
  alb_latency_alert  = var.alb_latency_alert

  # APM
  apm_requests_alert = var.apm_requests_alert
  apm_errors_alert   = var.apm_errors_alert
  apm_latency_alert  = var.apm_latency_alert
  apm_apdex_alert    = var.apm_apdex_alert

  # Kubernetes Alerts
  high_cpu_alert          = var.high_cpu_alert
  high_memory_alert       = var.high_memory_alert
  too_many_restarts_alert = var.too_many_restarts_alert
}

module "workflows" {
  source = "git::git@git.naspersclassifieds.com:olxeu/core-tech/core-tech-observability/tf-modules/tf-newrelic-workflows.git"

  team_name             = var.team_name
  route_by_alert_policy = true
  create_alert_policy   = true

  # Required for ARA. Uncomment when performing the configuration.
  # service_uuid = var.opslevel_uuid

  newrelic_account_key = "this_account"
  newrelic_config = {
    "this_account" = {
      account_name : data.newrelic_account.this.name
      account_id : data.newrelic_account.this.account_id
      region : "US"
    }
  }
  newrelic_secrets = {
    "this_account" = {
      api_key             = jsondecode(data.aws_secretsmanager_secret_version.nr_key.secret_string)["NEWRELIC_API_KEY"]
      insert_key          = jsondecode(data.aws_secretsmanager_secret_version.nr_key.secret_string)["NEWRELIC_INGEST_LICENSE"]
      workflows_slack_key = jsondecode(data.aws_secretsmanager_secret_version.nr_key.secret_string)["WORKFLOWS_SLACK_KEY"]
    }
  }
  workflows = [
    {
      name = var.service_name
      routes = [for channel_id in var.slack_channel_ids : {
        priorities       = ["HIGH", "MEDIUM", "CRITICAL"] // HIGH == WARNING in newrelic
        type             = "SLACK"
        slack_channel_id = channel_id
        }
      ]
    },
  ]
}
