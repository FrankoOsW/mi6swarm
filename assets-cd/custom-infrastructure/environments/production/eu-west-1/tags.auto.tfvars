/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/custom-infrastructure-integration-template

    To extend this module:
    - Add new .tf files as needed in this directory
    - For new variables: Create custom_vars.tf for definitions
    - Add variable values in environments/<env>/<region>/custom.auto.tfvars
    - Overwrite variables from a tfvars file: tfvars are loaded in alphabetic order so add the same variable in the in environments/<env>/<region>/<name>.override.auto.tfvars that way you will be able to change value of variable provided by service shaper
    - Best practice: Add new variables rather than overriding existing ones

    ⚠️ NOTE: Adding .tf files in this directory will only apply resources to this specific environment (production).
*/

default_tags = {
  // tag value for business_unit
  business_unit = "OLX"
  // tag value for business_unit_id
  business_unit_id = "57f344db-41a4-4938-a521-ad07148760e0"
  // tag value for customer_unit
  customer_unit = "Data"
  // tag value for customer_unit_id
  customer_unit_id = "a0f1c3e6-774c-429a-8fe4-d5a701bb4a59"
  // tag value for environment
  environment = "production"
  // tag value for lifecycle
  lifecycle = "poc"
  // tag value for managedby
  managedby = "https://git.naspersclassifieds.com/olxeu/mi6/mi6swarm"
  // tag value for opslevel-dependency-of
  opslevel-dependency-of = "01a0253d-8aa3-7ace-b3e6-2eab04e5f96f"
  // tag value for pillar_or_tribe
  pillar_or_tribe = "Domain_Data_Engineering"
  // tag value for pillar_or_tribe_id
  pillar_or_tribe_id = "9a8a3206-8df5-4d22-bc64-0c3d45ddfa02"
  // tag value for service_id
  service_id = "01a0253d-8aa3-7ace-b3e6-2eab04e5f96f"
  // tag value for service_name
  service_name = "mi6swarm"
  // tag value for stream
  stream = "Data"
  // tag value for stream_id
  stream_id = "a0f1c3e6-774c-429a-8fe4-d5a701bb4a59"
  // tag value for team_id
  team_id = "6ce1a074-94fa-4d85-93bd-66745316047b"
  // tag value for team_name
  team_name = "Core_DW_and_BI"
  // tag value for tier
  tier = "tier_4"
}