output "policy_id" {
  description = "The created tag policy's AWS-assigned policy id."
  value       = module.policy.policies["require_environment_tag"].id
}

output "policy_arn" {
  description = "The created tag policy's ARN."
  value       = module.policy.policies["require_environment_tag"].arn
}
