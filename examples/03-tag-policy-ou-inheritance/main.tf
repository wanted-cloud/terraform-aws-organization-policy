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
      target_id  = "ou-aaaa-bbbbbbbb"
    }
  }
}
