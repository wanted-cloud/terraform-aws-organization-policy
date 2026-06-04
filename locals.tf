locals {
  // Here you can define module metadata
  definitions = {
    tags = {
      ManagedBy             = "Terraform"
      "wanted-cloud:module" = "terraform-aws-organization-policy"
      "wanted-cloud:tier"   = "T1.03"
    }
    validator_expressions = {
      // AWS Organizations Policy resource
      aws_organizations_policy_type                    = "SERVICE_CONTROL_POLICY,TAG_POLICY,BACKUP_POLICY,AISERVICES_OPT_OUT_POLICY,RESOURCE_CONTROL_POLICY,CHATBOT_POLICY"
      aws_organizations_policy_name                    = "^[A-Za-z0-9_-]{1,128}$"
      aws_organizations_policy_description_max_length  = "512"
      aws_organizations_policy_content_size_scp_rcp    = "5120"
      aws_organizations_policy_content_size_ai_opt_out = "2500"
      aws_organizations_policy_content_size_default    = "10000"
      // AWS Organizations Policy Attachment resource
      aws_organizations_policy_attachment_target_id                           = "^(r-[a-z0-9]{4,32}|ou-[a-z0-9]{4,32}-[a-z0-9]{8,32}|[0-9]{12})$"
      aws_organizations_policy_attachment_per_target_per_type_limit_scp_class = "5"
      aws_organizations_policy_attachment_per_target_per_type_limit_tag_class = "10"
      aws_organizations_policy_attachment_policy_key_ref                      = "in-module"
    }
    validator_error_messages = {
      // AWS Organizations Policy resource
      aws_organizations_policy_type                    = "policy.type must be one of: SERVICE_CONTROL_POLICY, TAG_POLICY, BACKUP_POLICY, AISERVICES_OPT_OUT_POLICY, RESOURCE_CONTROL_POLICY, CHATBOT_POLICY."
      aws_organizations_policy_name                    = "policy.name must be 1-128 characters and contain only alphanumerics, underscores, and hyphens."
      aws_organizations_policy_description_max_length  = "policy.description must be 512 characters or fewer."
      aws_organizations_policy_content_size_scp_rcp    = "policy.content for SCP/RCP must be 5120 bytes or fewer."
      aws_organizations_policy_content_size_ai_opt_out = "policy.content for AISERVICES_OPT_OUT_POLICY must be 2500 bytes or fewer."
      aws_organizations_policy_content_size_default    = "policy.content for this type must be 10000 bytes or fewer."
      // AWS Organizations Policy Attachment resource
      aws_organizations_policy_attachment_target_id                           = "attachment.target_id must be a root id (r-xxxx), OU id (ou-xxxx-yyyyyyyy), or 12-digit AWS account id."
      aws_organizations_policy_attachment_per_target_per_type_limit_scp_class = "Per-target limit exceeded: AWS allows at most 5 SCP/RCP/AI-opt-out/Chatbot policies attached to a single target."
      aws_organizations_policy_attachment_per_target_per_type_limit_tag_class = "Per-target limit exceeded: AWS allows at most 10 tag/backup policies attached to a single target."
      aws_organizations_policy_attachment_policy_key_ref                      = "attachment.policy_key must reference a key present in var.policies."
    }
  }
}
