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
# put production variables here
eks_cluster_oidc = "arn:aws:iam::021427824859:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/6F19A68BD4B12B79A853C1F94B2EC01D"
