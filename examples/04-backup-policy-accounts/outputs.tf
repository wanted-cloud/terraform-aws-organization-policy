output "policy_id" {
  description = "The created backup policy's AWS-assigned policy id."
  value       = module.policy.policies["weekly_long_retention"].id
}

output "attachment_count" {
  description = "Number of attachments created (should be 2, one per target account)."
  value       = length(module.policy.attachments)
}

output "attachment_ids" {
  description = "All created attachment ids."
  value       = [for k, v in module.policy.attachments : v.id]
}
