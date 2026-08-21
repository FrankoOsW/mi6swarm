/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template

    ⚠️ DO NOT modify this file directly.
    To extend functionality: Reference resources from custom-infrastructure/ directory only.
    Variables are loaded in lexical order (as per https://developer.hashicorp.com/terraform/language/values/variables#assign-values-to-variables), to override any variable located here, you need to add <component>.override.auto.tfvars file and override variables there.

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
