output "policies" {
  description = "Map of created policies, keyed by the user's var.policies key. Each entry exposes the AWS-assigned id, arn, plus pass-through of name, type, and description for convenient referencing in downstream modules."
  value = {
    for k, p in aws_organizations_policy.this : k => {
      id          = p.id
      arn         = p.arn
      name        = p.name
      type        = p.type
      description = p.description
    }
  }
}

output "attachments" {
  description = "Map of created policy attachments, keyed by the user's var.attachments key. Each entry exposes the AWS-assigned attachment id, the resolved policy_id, the target_id, and a pass-through of the policy_key for traceability."
  value = {
    for k, a in aws_organizations_policy_attachment.this : k => {
      id         = a.id
      policy_id  = a.policy_id
      target_id  = a.target_id
      policy_key = var.attachments[k].policy_key
    }
  }
}

output "policy_ids_by_type" {
  description = "Convenience output: map of policy_type => list of created policy IDs. Lets downstream modules discover policies by AWS type without knowing the user's for_each keys. Useful when composing into landing-zone blueprints that filter by type."
  value = {
    for t in distinct([for p in aws_organizations_policy.this : p.type]) :
    t => [for p in aws_organizations_policy.this : p.id if p.type == t]
  }
}

output "policy_ids_by_key" {
  description = "Convenience output: map of user-chosen var.policies key => created policy id. Equivalent to a one-field projection of the full policies output; useful when downstream code only needs the id."
  value       = { for k, p in aws_organizations_policy.this : k => p.id }
}
