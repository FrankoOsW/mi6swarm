locals {
  entity_service_name          = "${var.service_name}-${var.environment}"
  create_service_levels        = var.environment == "production" && var.enable_service_levels && var.kubernetes_ingress_name != ""
  has_apm_application_entity   = try(data.newrelic_entity.has_apm_application_entity[0], null) != null && try(data.newrelic_entity.has_apm_application_entity[0].guid, null) != null
  has_otel_application_entity  = try(data.newrelic_entity.has_otel_application_entity[0], null) != null && try(data.newrelic_entity.has_otel_application_entity[0].guid, null) != null
  has_application_entity       = local.has_otel_application_entity || local.has_apm_application_entity
  apm_application_entity_guid  = local.has_apm_application_entity ? data.newrelic_entity.has_apm_application_entity[0].guid : null
  otel_application_entity_guid = local.has_otel_application_entity ? data.newrelic_entity.has_otel_application_entity[0].guid : null
  application_entity_guid      = local.has_application_entity ? coalesce(local.otel_application_entity_guid, local.apm_application_entity_guid) : null

  # Use OTel New Relic Entitty first. Use the APM Entity as an alternative.
  main_entity = local.has_application_entity ? {
    application_name = coalesce(try(data.newrelic_entity.has_otel_application_entity[0].name, null), try(data.newrelic_entity.has_apm_application_entity[0].name, null))
    nr_account_id    = var.monitoring_account_id
    domain           = coalesce(try(data.newrelic_entity.has_otel_application_entity[0].domain, null), try(data.newrelic_entity.has_apm_application_entity[0].domain, null))
    type             = coalesce(try(data.newrelic_entity.has_otel_application_entity[0].type, null), try(data.newrelic_entity.has_apm_application_entity[0].type, null))
  } : null
}

# Does OTel New Relic Entitty exists?
data "newrelic_entity" "has_otel_application_entity" {
  count            = local.create_service_levels ? 1 : 0
  name             = local.entity_service_name
  account_id       = var.monitoring_account_id
  domain           = "EXT"
  type             = "SERVICE"
  ignore_not_found = true
}

# Does APM New Relic Entitty exists?
data "newrelic_entity" "has_apm_application_entity" {
  count            = local.create_service_levels ? 1 : 0
  name             = local.entity_service_name
  account_id       = var.monitoring_account_id
  domain           = "APM"
  type             = "APPLICATION"
  ignore_not_found = true
}


module "service_levels" {
  count  = local.create_service_levels && local.has_application_entity ? 1 : 0
  source = "git::git@git.naspersclassifieds.com:olxeu/core-tech/core-tech-observability/tf-modules/tf-newrelic-slo-deployment.git?ref=v1.3.0"

  name_prefix_enabled = true
  main_entity         = local.main_entity

  service_owner = "CT Observability"
  alerting = {
    enabled         = false
    slow_burn       = { enabled = false }
    fast_burn       = { enabled = false }
    warning_enabled = false
    policy_id       = module.workflows.policy_ids[var.service_name]
  }
  metrics_slo = {
    nr_account_id    = var.monitoring_account_id
    environment      = var.environment
    time_window_days = var.slo_time_window_days
    metrics = {

      availability = {
        name        = "${var.service_name} - ${var.target_slo}% successful resquests"
        description = "Over a rolling ${var.slo_time_window_days}-day period, 99% of all requests to ${var.service_name} load balancer are successful."
        target_slo  = var.target_slo

        valid_events = {
          from  = "Metric"
          where = "`tags.environment` = '${var.environment}' AND `aws.applicationelb.TargetGroup` like '%${var.kubernetes_ingress_name}%' AND metricName = 'aws.applicationelb.RequestCount.byTargetGroup'"
          select = {
            attribute = "`aws.applicationelb.RequestCount.byTargetGroup`"
            function  = "SUM"
            threshold = 0
          }
        }
        good_events = {
          from  = "Metric"
          where = "`tags.environment` = '${var.environment}' AND `aws.applicationelb.TargetGroup` like '%${var.kubernetes_ingress_name}%' AND metricName = 'aws.applicationelb.HTTPCode_Target_2XX_Count'"
          select = {
            attribute = "`aws.applicationelb.HTTPCode_Target_2XX_Count`"
            function  = "SUM"
            threshold = 0
          }
        }

      }
    }
  }

  opslevel-dependency-of = var.service_name
  managedby              = var.service_name
}