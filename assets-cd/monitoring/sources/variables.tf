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

variable "service_name" {
  type        = string
  description = "Service name."
}

variable "service_uid" {
  type        = string
  description = "Service UID."
}

variable "opslevel_uuid" {
  type        = string
  description = "Opslevel service UUID (either short or full)."
  default     = ""
}

variable "monitoring_account_id" {
  type        = string
  description = "Account ID of the monitoring system."
}

variable "kubernetes_cluster_name" {
  type        = string
  description = "Kubernetes Cluster Name where the service is deployed."
}

variable "kubernetes_namespace_name" {
  type        = string
  description = "Kubernetes Namespace Name where the service is deployed."
}

variable "kubernetes_ingress_name" {
  type        = string
  description = "Service Kubernetes Ingress of the service."
}

variable "team_name" {
  type        = string
  description = "Team name owning the service."
}

variable "slack_channel_ids" {
  type        = list(string)
  description = "The slack channels in which the team will receive the alerts notifications for the service."
}

variable "aws_region" {
  description = "AWS Region."
  type        = string
}

variable "default_tags" {
  type = map(string)
}

variable "pages" {
  type = map(bool)
}

variable "environment" {
  description = "injected by terragrunt"
  type        = string
}

variable "enable_service_levels" {
  description = "Enable New Relic service levels resources that require events-to-metrics permissions."
  type        = bool
  default     = true
}

variable "target_slo" {
  description = "Target SLO percentage for availability service level."
  type        = string
  default     = "99"
}

variable "slo_time_window_days" {
  description = "Rolling time window in days for the availability SLO calculation."
  type        = number
  default     = 28
}

variable "alb_requests_alert" {
  description = "ALB requests anomaly alert configuration."
  type = object({
    status                       = optional(bool, false)
    warning_deviation_threshold  = optional(number, 4)
    warning_duration             = optional(number, 120)
    critical_deviation_threshold = optional(number, 6)
    critical_duration            = optional(number, 120)
    aggregation_window           = optional(number, 60)
    aggregation_delay            = optional(number, 120)
  })
  default = {}
}

variable "alb_errors_alert" {
  description = "ALB errors alert configuration."
  type = object({
    status             = optional(bool, false)
    warning_threshold  = optional(number, 3)
    warning_duration   = optional(number, 60)
    critical_threshold = optional(number, 5)
    critical_duration  = optional(number, 60)
    aggregation_window = optional(number, 60)
    aggregation_delay  = optional(number, 120)
  })
  default = {}
}

variable "alb_latency_alert" {
  description = "ALB latency alert configuration."
  type = object({
    status             = optional(bool, false)
    warning_threshold  = optional(number, 100)
    warning_duration   = optional(number, 60)
    critical_threshold = optional(number, 150)
    critical_duration  = optional(number, 60)
    aggregation_window = optional(number, 60)
    aggregation_delay  = optional(number, 120)
  })
  default = {}
}

variable "apm_requests_alert" {
  description = "APM requests anomaly alert configuration."
  type = object({
    status                       = optional(bool, false)
    warning_deviation_threshold  = optional(number, 4)
    warning_duration             = optional(number, 120)
    critical_deviation_threshold = optional(number, 6)
    critical_duration            = optional(number, 120)
    aggregation_window           = optional(number, 60)
    aggregation_delay            = optional(number, 120)
  })
  default = {}
}

variable "apm_errors_alert" {
  description = "APM errors alert configuration."
  type = object({
    status             = optional(bool, false)
    warning_threshold  = optional(number, 3)
    warning_duration   = optional(number, 60)
    critical_threshold = optional(number, 5)
    critical_duration  = optional(number, 60)
    aggregation_window = optional(number, 60)
    aggregation_delay  = optional(number, 120)
  })
  default = {}
}

variable "apm_latency_alert" {
  description = "APM latency alert configuration."
  type = object({
    status             = optional(bool, false)
    warning_threshold  = optional(number, 100)
    warning_duration   = optional(number, 60)
    critical_threshold = optional(number, 150)
    critical_duration  = optional(number, 60)
    aggregation_window = optional(number, 60)
    aggregation_delay  = optional(number, 120)
  })
  default = {}
}

variable "apm_apdex_alert" {
  description = "APM apdex alert configuration."
  type = object({
    status             = optional(bool, false)
    warning_threshold  = optional(number, 0.8)
    warning_duration   = optional(number, 60)
    critical_threshold = optional(number, 0.7)
    critical_duration  = optional(number, 60)
    aggregation_window = optional(number, 60)
    aggregation_delay  = optional(number, 120)
  })
  default = {}
}

variable "high_cpu_alert" {
  description = "Kubernetes high CPU alert configuration."
  type = object({
    status             = optional(bool, false)
    warning_threshold  = optional(number, 90)
    warning_duration   = optional(number, 60)
    critical_threshold = optional(number, 95)
    critical_duration  = optional(number, 60)
    aggregation_window = optional(number, 60)
    aggregation_delay  = optional(number, 120)
  })
  default = {}
}

variable "high_memory_alert" {
  description = "Kubernetes high memory alert configuration."
  type = object({
    status             = optional(bool, false)
    warning_threshold  = optional(number, 85)
    warning_duration   = optional(number, 60)
    critical_threshold = optional(number, 90)
    critical_duration  = optional(number, 60)
    aggregation_window = optional(number, 60)
    aggregation_delay  = optional(number, 120)
  })
  default = {}
}

variable "too_many_restarts_alert" {
  description = "Kubernetes too many restarts alert configuration."
  type = object({
    status             = optional(bool, false)
    warning_threshold  = optional(number, 5)
    warning_duration   = optional(number, 60)
    critical_threshold = optional(number, 10)
    critical_duration  = optional(number, 60)
    aggregation_window = optional(number, 60)
    aggregation_delay  = optional(number, 120)
  })
  default = {}
}