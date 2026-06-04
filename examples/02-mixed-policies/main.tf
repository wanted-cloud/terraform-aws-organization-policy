/*
 * Example: mixed policies (SCP + Tag + Backup) attached across OU and account targets.
 *
 * Demonstrates user story S2 from the T1.03 plan.
 * Composes 3 modules conceptually: terraform-aws-organization (T1.01),
 * terraform-aws-organization-unit (T1.0X, not yet implemented), and this
 * module (T1.03). OU ids are literal placeholders pending the OU module
 * shipping a stable outputs interface; account ids are literals as expected.
 *
 * Notes the policy_ids_by_type convenience output downstream consumers
 * may want to pivot on.
 */

module "org" {
  source = "git::https://github.com/wanted-cloud/terraform-aws-organization.git?ref=main"

  feature_set = "ALL"
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
    "BACKUP_POLICY",
  ]
}

module "policy" {
  source = "../.."

  policies = {
    deny_console_root_login = {
      name = "deny_console_root_login"
      type = "SERVICE_CONTROL_POLICY"
      content = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid      = "DenyRootLogin"
          Effect   = "Deny"
          Action   = ["*"]
          Resource = ["*"]
          Condition = {
            StringLike = {
              "aws:PrincipalArn" = ["arn:aws:iam::*:root"]
            }
          }
        }]
      })
      description = "Denies all actions performed by the root user across the org."
    }

    require_environment_tag = {
      name = "require_environment_tag"
      type = "TAG_POLICY"
      content = jsonencode({
        tags = {
          Environment = {
            tag_key = { "@@assign" = "Environment" }
            tag_value = {
              "@@assign" = ["production", "staging", "development"]
            }
          }
        }
      })
      description = "Requires the Environment tag with one of three allowed values."
    }

    daily_backup_workloads = {
      name = "daily_backup_workloads"
      type = "BACKUP_POLICY"
      content = jsonencode({
        plans = {
          DailyBackups = {
            regions = { "@@assign" = ["us-east-1"] }
            rules = {
              Hourly = {
                schedule_expression      = { "@@assign" = "cron(0 1 ? * * *)" }
                target_backup_vault_name = { "@@assign" = "Default" }
                lifecycle = {
                  delete_after_days = { "@@assign" = 30 }
                }
              }
            }
          }
        }
      })
      description = "Daily backup at 01:00 with 30-day retention, targeting Default vault."
    }
  }

  attachments = {
    # SCP to root — applies org-wide.
    deny_root_login_to_root = {
      policy_key = "deny_console_root_login"
      target_id  = module.org.root_id
    }

    # Tag policy to a Workloads OU.
    require_env_tag_to_workloads = {
      policy_key = "require_environment_tag"

      # Literal placeholder until terraform-aws-organization-unit ships outputs.
      # Replace with: module.ou.organizational_units["workloads"].id
      target_id = "ou-aaaa-bbbbbbbb"
    }

    # Backup policy directly to a Production account.
    daily_backup_to_prod_account = {
      policy_key = "daily_backup_workloads"
      target_id  = "111111111111"
    }
  }
}
