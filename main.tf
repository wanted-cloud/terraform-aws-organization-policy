/*
 * # wanted-cloud/terraform-aws-organization-policy
 *
 * Terraform building block managing AWS Organizations policies and their attachments to root, OUs, or accounts.
 */

resource "aws_organizations_policy" "this" {
  for_each = var.policies

  name        = each.value.name
  type        = each.value.type
  content     = each.value.content
  description = each.value.description

  tags = merge(local.metadata.tags, var.tags, each.value.tags)

  # NOTE: `aws_organizations_policy` does not expose a `timeouts {}` block in the
  # AWS provider schema (v5.x). Resource-type-keyed timeout overrides are still
  # surfaced through var.metadata.resource_timeouts for cross-module consistency
  # but cannot be wired on this resource. See README "Gotchas" for details.

  lifecycle {
    precondition {
      condition     = contains(data.aws_organizations_organization.this.enabled_policy_types, each.value.type)
      error_message = "Policy type ${each.value.type} is not enabled at the AWS Organization root. Enable it via the T1.01 terraform-aws-organization module's var.enabled_policy_types before applying this policy."
    }
  }
}
