/*
    This file is auto-generated from a template.
    Template: https://git.naspersclassifieds.com/olxeu/core-tech/core-tech-devx/s2-integration-templates/custom-infrastructure-integration-template

    To extend this module:
    - Add new .tf files as needed in this directory
    - For new variables: Create custom_vars.tf for definitions
    - Add variable values in environments/<env>/<region>/custom.auto.tfvars
    - Overwrite variables from a tfvars file: tfvars are loaded in alphabetic order so add the same variable in the in environments/<env>/<region>/<name>.override.auto.tfvars that way you will be able to change value of variable provided by service shaper
    - Best practice: Add new variables rather than overriding existing ones
*/

# data "aws_iam_policy_document" "read-dynamodb-table" {
#   statement {
#     actions   = ["dynamodb:GetItem"]
#     resources = ["arn:aws:dynamodb:eu-west-1:12345:table/foo-bar"]
#   }
# }
#
# resource "aws_iam_policy" "read-dynamodb-table" {
#   name   = "read-dynamodb-table"
#   policy = data.aws_iam_policy_document.read-dynamodb-table.json
# }
#
# resource "aws_iam_policy_attachment" "read-dynamodb-table" {
#   name       = "read-dynamodb-table"
#   policy_arn = aws_iam_policy.read-dynamodb-table.arn
#   roles      = [""]
# }
