/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template
    
    ⚠️ DO NOT modify this file directly.
*/

module "stream" {
  source          = "citizen.mgmt.eu.olx.org/olxeu/tf-unified-logging-stream/aws"
  version         = "2.0.0"
  create          = var.create_logging_stream
  environment     = var.environment
  stream_name     = var.project_name
  alert_email     = var.team_email
  aws_account_ids = var.aws_account_ids

  # Use CT Observability general channel if none is provided
  slack_channels = length(var.slack_channels) > 0 ? var.slack_channels : ["#ct-o11y-general-notifications"]

  regions        = [var.aws_region]
  daily_quota    = var.daily_quota
  time_field     = var.time_field
  replicas       = var.replicas
  shards         = var.shards
  privacy_filter = var.privacy_filter

  # Disable tagging if team slack channel is provided
  slack_handle_enabled = length(var.slack_channels) > 0 ? false : var.slack_handle_enabled
  team_name            = var.team_name
  team_slack_handle    = var.team_slack_handle
  tags                 = var.default_tags
}

output "info" {
  value = module.stream.info
}
