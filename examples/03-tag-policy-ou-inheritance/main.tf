/*
 * Example: tag policy attached to an OU, with implicit inheritance.
 *
 * Demonstrates user story S3 from the T1.03 plan.
 * Composes 3 modules conceptually: terraform-aws-organization (T1.01),
 * terraform-aws-organization-unit (T1.0X, not yet implemented), and this
 * module (T1.03). Currently the OU module is referenced via a literal
 * placeholder target_id — see comment on the attachment target_id.
 */

module "org" {
  source = "git::https://github.com/wanted-cloud/terraform-aws-organization.git?ref=main"

  feature_set          = "ALL"
  enabled_policy_types = ["TAG_POLICY"]
}

module "policy" {
  source = "../.."

  policies = {
    require_environment_tag = {
      name = "require_environment_tag"
      type = "TAG_POLICY"
      content = jsonencode({
        tags = {
          Environment = {
            tag_key = {
              "@@assign" = "Environment"
            }
            tag_value = {
              "@@assign" = ["production", "staging", "development"]
            }
            enforced_for = {
              "@@assign" = ["ec2:instance"]
            }
          }
        }
      })
      description = "Requires every resource (EC2 instances enforced) to carry an Environment tag with one of three allowed values."
    }
  }

  attachments = {
    require_environment_tag_to_workloads = {
      policy_key = "require_environment_tag"

      # Literal placeholder until terraform-aws-organization-unit ships outputs.
      # Replace with: module.ou.organizational_units["workloads"].id
      target_id = "ou-aaaa-bbbbbbbb"
    }
  }
}
