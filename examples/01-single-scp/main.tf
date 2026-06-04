/*
 * Example: single SCP attached to org root.
 *
 * Demonstrates user story S1 from the T1.03 plan.
 * Composes 2 modules in this example: terraform-aws-organization (T1.01)
 * + this module (T1.03). The OU module is not needed because the attachment
 * target is the org root, available directly via module.org.root_id.
 */

module "org" {
  source = "git::https://github.com/wanted-cloud/terraform-aws-organization.git?ref=main"

  feature_set          = "ALL"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

module "policy" {
  source = "../.."

  policies = {
    deny_us_east_1 = {
      name = "deny_us_east_1"
      type = "SERVICE_CONTROL_POLICY"
      content = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid      = "DenyUsEast1"
          Effect   = "Deny"
          Action   = "*"
          Resource = "*"
          Condition = {
            StringEquals = {
              "aws:RequestedRegion" = "us-east-1"
            }
          }
        }]
      })
      description = "Denies all actions in us-east-1 across the org."
    }
  }

  attachments = {
    deny_us_east_1_to_root = {
      policy_key = "deny_us_east_1"
      target_id  = module.org.root_id
    }
  }
}
