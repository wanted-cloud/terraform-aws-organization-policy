output "policy_id" {
  description = "The created SCP's AWS-assigned policy id."
  value       = module.policy.policies["deny_us_east_1"].id
}

output "attachment_id" {
  description = "The created attachment's id (composite policy_id:target_id)."
  value       = module.policy.attachments["deny_us_east_1_to_root"].id
}
