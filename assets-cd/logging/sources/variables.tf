/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template
    
    ⚠️ DO NOT modify this file directly.
*/

variable "aws_account_ids" {
  description = "The stream's account ids"
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "injected by terragrunt"
  type        = string
}

variable "environment" {
  description = "injected by terragrunt"
  type        = string
}

variable "project_name" {
  description = "injected by terragrunt"
  type        = string
}

variable "default_tags" {
  type = map(string)
}

variable "team_email" {
  type        = string
  description = "The e-mail address which the team will receive the notifications. E.g. Quota reached."
  default     = ""
}

variable "slack_channels" {
  type        = list(string)
  description = "The slack channels in which the team will receive the alerts notifications. E.g. Quota reached."
  default     = []
}

variable "daily_quota" {
  type        = number
  description = "The max daily quota in GB."
  default     = 1
}

variable "time_field" {
  type        = string
  description = "The default time field."
  default     = "time"
}

variable "replicas" {
  type        = string
  description = "The number of replicas."
  default     = "default"
}

variable "shards" {
  type        = string
  description = "The number of shards."
  default     = "default"
}

variable "privacy_filter" {
  type        = string
  description = "The privacy filter."
  default     = "default"
}

variable "create_logging_stream" {
  type        = bool
  description = "Whether to create Unified Logging Stream resources ."
  default     = true
}

variable "slack_handle_enabled" {
  description = "Whether to tag or not the owners on slack."
  type        = bool
  default     = true
}

variable "team_name" {
  description = "The team name that owns the kinesis stream."
  type        = string
  default     = ""
}

variable "team_slack_handle" {
  description = "The slack handle of the team that owns the kinesis stream."
  type        = string
  default     = ""
}