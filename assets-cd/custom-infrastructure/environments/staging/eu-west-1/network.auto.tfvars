/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/custom-infrastructure-integration-template

    To extend this module:
    - Add new .tf files as needed in this directory
    - For new variables: Create custom_vars.tf for definitions
    - Add variable values in environments/<env>/<region>/custom.auto.tfvars
    - Overwrite variables from a tfvars file: tfvars are loaded in alphabetic order so add the same variable in the in environments/<env>/<region>/<name>.override.auto.tfvars that way you will be able to change value of variable provided by service shaper
    - Best practice: Add new variables rather than overriding existing ones

    ⚠️ NOTE: Adding .tf files in this directory will only apply resources to this specific environment (staging).
*/

vpc_id = "vpc-04b43d0fdc9184e5e"
private_subnet_ids = [
  "subnet-0f1eefdf6c3017a88",
  "subnet-0cc36ecdae9302c2b",
  "subnet-09191d90dd96489b9",
]
public_subnet_ids = [
  "subnet-0b9d11313e045881b",
  "subnet-0d997f0669f45528d",
  "subnet-098ea14b896dc057a",
]
eks_private_subnet_ids = [
  "subnet-0f1eefdf6c3017a88",
  "subnet-0cc36ecdae9302c2b",
  "subnet-09191d90dd96489b9",
  "subnet-098ff3c653df6021c",
  "subnet-04c8511a002fbb31c",
  "subnet-0d371feb825e65dfe",
]
eks_public_subnet_ids = [
  "subnet-0514547c7ec05e049",
  "subnet-0a6fc76f729d7df63",
  "subnet-0ef69c0ccbe044397",
]

availability_zones = [
  "eu-west-1a",
  "eu-west-1b",
  "eu-west-1c",
]
