/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/atlantis-integration-template

    ⚠️ DO NOT modify this file directly.
    To extend functionality: Reference resources from custom-infrastructure/ directory only.
    Variables are loaded in lexical order (as per https://developer.hashicorp.com/terraform/language/values/variables#assign-values-to-variables), to override any variable located here, you need to add <component>.override.auto.tfvars file and override variables there.
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
