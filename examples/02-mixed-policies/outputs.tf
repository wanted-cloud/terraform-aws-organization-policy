output "policies_by_type" {
  description = "Map of policy_type => list of created policy IDs. Demonstrates the policy_ids_by_type convenience output."
  value       = module.policy.policy_ids_by_type
}

output "scp_id" {
  description = "The id of the SCP authored in this example."
  value       = module.policy.policies["deny_console_root_login"].id
}

output "tag_policy_id" {
  description = "The id of the tag policy authored in this example."
  value       = module.policy.policies["require_environment_tag"].id
}

output "backup_policy_id" {
  description = "The id of the backup policy authored in this example."
  value       = module.policy.policies["daily_backup_workloads"].id
}
