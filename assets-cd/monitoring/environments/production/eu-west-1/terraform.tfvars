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

service_name = "mi6swarm"
service_uid  = "01a0253d-8aa3-7ace-b3e6-2eab04e5f96f"

// ARA configuration. Uncomment when performing the configuration.
// Set your service short (10 characters) or full (~40 characters) UUID from the opslevel. you can find it in the Alias section of your service page.
// For details please check: https://naspersclassifieds.atlassian.net/wiki/spaces/CORETECH/pages/57880903722/How+to+onboard+my+service+to+the+Unified+Service+Alert+Routing+for+IMP+aka+ARA
// opslevel_uuid = "YOUR SERVICE OPSLEVEL UUID"

team_name                 = "OLX - Data - Domain Data Engineering - Core DW & BI"
aws_region                = "eu-west-1"
monitoring_account_id     = "3100679"
kubernetes_cluster_name   = "eu-data-k8s"
kubernetes_namespace_name = "mi6swarm"
kubernetes_ingress_name   = "mi6swarm-svc"
slack_channel_ids = [
]

pages = {
  a_overview    = true
  b_application = true
  c_kubernetes  = true
  d_networking  = true
  e_changes     = true
  f_rds         = false
}

alb_requests_alert = {
  status                       = false
  warning_deviation_threshold  = 4
  warning_duration             = 120
  critical_deviation_threshold = 6
  critical_duration            = 120
  aggregation_window           = 60
  aggregation_delay            = 120
}

alb_errors_alert = {
  status             = false
  warning_threshold  = 3
  warning_duration   = 60
  critical_threshold = 5
  critical_duration  = 60
  aggregation_window = 60
  aggregation_delay  = 120
}

alb_latency_alert = {
  status             = false
  warning_threshold  = 100
  warning_duration   = 60
  critical_threshold = 150
  critical_duration  = 60
  aggregation_window = 60
  aggregation_delay  = 120
}

apm_requests_alert = {
  status                       = false
  warning_deviation_threshold  = 4
  warning_duration             = 120
  critical_deviation_threshold = 6
  critical_duration            = 120
  aggregation_window           = 60
  aggregation_delay            = 120
}

apm_errors_alert = {
  status             = false
  warning_threshold  = 3
  warning_duration   = 60
  critical_threshold = 5
  critical_duration  = 60
  aggregation_window = 60
  aggregation_delay  = 120
}

apm_latency_alert = {
  status             = false
  warning_threshold  = 100
  warning_duration   = 60
  critical_threshold = 150
  critical_duration  = 60
  aggregation_window = 60
  aggregation_delay  = 120
}

apm_apdex_alert = {
  status             = false
  warning_threshold  = 0.8
  warning_duration   = 60
  critical_threshold = 0.7
  critical_duration  = 60
  aggregation_window = 60
  aggregation_delay  = 120
}

high_cpu_alert = {
  status             = false
  warning_threshold  = 90
  warning_duration   = 60
  critical_threshold = 95
  critical_duration  = 60
  aggregation_window = 60
  aggregation_delay  = 120
}

high_memory_alert = {
  status             = false
  warning_threshold  = 85
  warning_duration   = 60
  critical_threshold = 90
  critical_duration  = 60
  aggregation_window = 60
  aggregation_delay  = 120
}

too_many_restarts_alert = {
  status             = false
  warning_threshold  = 5
  warning_duration   = 60
  critical_threshold = 10
  critical_duration  = 60
  aggregation_window = 60
  aggregation_delay  = 120
}

