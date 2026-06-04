/*
 * # wanted-cloud/terraform-aws-organization-policy
 *
 * Data sources resolving runtime metadata about the AWS Organization (e.g. enabled policy types on the root) used by module preconditions.
 */

data "aws_organizations_organization" "this" {}
