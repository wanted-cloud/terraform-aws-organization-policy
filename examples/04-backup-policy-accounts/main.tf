terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "org" {
  source = "git::https://github.com/wanted-cloud/terraform-aws-organization.git?ref=main"

  feature_set          = "ALL"
  enabled_policy_types = ["BACKUP_POLICY"]
}

module "policy" {
  source = "../.."

  policies = {
    weekly_long_retention = {
      name = "weekly_long_retention"
      type = "BACKUP_POLICY"
      content = jsonencode({
        plans = {
          WeeklyLongRetention = {
            regions = { "@@assign" = ["us-east-1", "us-west-2"] }
            rules = {
              Weekly = {
                schedule_expression      = { "@@assign" = "cron(0 5 ? * SUN *)" }
                target_backup_vault_name = { "@@assign" = "Default" }
                lifecycle = {
                  delete_after_days = { "@@assign" = 365 }
                }
              }
            }
          }
        }
      })
      description = "Weekly Sunday backup with 365-day retention, replicated across two regions."
    }
  }

  attachments = {
    weekly_to_prod_account = {
      policy_key = "weekly_long_retention"
      target_id  = "111111111111"
    }

    weekly_to_security_account = {
      policy_key = "weekly_long_retention"
      target_id  = "222222222222"
    }
  }
}
