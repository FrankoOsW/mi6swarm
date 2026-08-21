/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template

    To extend this module:
    - Add new .tf files as needed in this directory
    - For new variables: Create custom_vars.tf for definitions
    - Add variable values in environments/<env>/<region>/custom.auto.tfvars
    - Overwrite variables from a tfvars file: tfvars are loaded in alphabetic order so add the same variable in the in environments/<env>/<region>/<name>.override.auto.tfvars that way you will be able to change value of variable provided by service shaper
    - Best practice: Add new variables rather than overriding existing ones

    ⚠️ NOTE: Adding .tf files in this directory will only apply resources to this specific environment (staging).
*/
# put production variables here
create_logging_stream = true
team_email            = "olx-data-domaindataengineering-coredw_bi@olx.com"
slack_channels = [
]
daily_quota          = 1
time_field           = "time"
replicas             = "default"
shards               = "default"
privacy_filter       = "default"
slack_handle_enabled = true
team_name            = "OLX - Data - Domain Data Engineering - Core DW & BI"
team_slack_handle    = "@olx-data-domaindataengineering-coredw_bi"
