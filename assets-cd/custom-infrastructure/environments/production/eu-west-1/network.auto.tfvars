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

vpc_id = "vpc-05872d95fe8e453f0"
private_subnet_ids = [
  "subnet-04d3fd6eb0164f8dc",
  "subnet-0e495d73b2a101247",
  "subnet-06972c331d09f0d69",
]
public_subnet_ids = [
  "subnet-0cb72dc2b07f2f4ea",
  "subnet-0dbc0104d4399e206",
  "subnet-09667796e85ad9829",
]
eks_private_subnet_ids = [
  "subnet-04d3fd6eb0164f8dc",
  "subnet-0e495d73b2a101247",
  "subnet-06972c331d09f0d69",
  "subnet-01430ba7d43f46f4e",
  "subnet-058118667ed0a7b85",
  "subnet-0ce10548a30ea9894",
]
eks_public_subnet_ids = [
  "subnet-0cb72dc2b07f2f4ea",
  "subnet-0dbc0104d4399e206",
  "subnet-09667796e85ad9829",
]

availability_zones = [
  "eu-west-1a",
  "eu-west-1b",
  "eu-west-1c",
]
