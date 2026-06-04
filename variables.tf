variable "tags" {
  description = "Module-wide tags applied to every policy resource. Merged with metadata tags (lower precedence) and per-policy tags (higher precedence) per ADR-O5."
  type        = map(string)
  default     = {}
}

variable "policies" {
  description = <<-EOT
    Map of AWS Organizations policies to author. Key is a stable, user-chosen
    identifier referenced by var.attachments[*].policy_key. Each entry defines
    a policy by type, name, content, optional description, and optional tags.

    Policy `content` is a JSON string — typically produced via file("./scp.json"),
    jsonencode({...}), or heredoc. Per-type content size limits enforced at plan
    time (override via var.metadata.validator_expressions):
      - SERVICE_CONTROL_POLICY    / RESOURCE_CONTROL_POLICY : 5120 bytes
      - AISERVICES_OPT_OUT_POLICY                            : 2500 bytes
      - TAG_POLICY / BACKUP_POLICY / CHATBOT_POLICY          : 10000 bytes
  EOT

  type = map(object({
    name        = string
    type        = string
    content     = string
    description = optional(string, null)
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.policies :
      contains(split(",", local.metadata.validator_expressions["aws_organizations_policy_type"]), v.type)
    ])
    error_message = local.metadata.validator_error_messages["aws_organizations_policy_type"]
  }

  validation {
    condition = alltrue([
      for k, v in var.policies :
      can(regex(local.metadata.validator_expressions["aws_organizations_policy_name"], v.name))
    ])
    error_message = local.metadata.validator_error_messages["aws_organizations_policy_name"]
  }

  validation {
    condition = alltrue([
      for k, v in var.policies :
      v.description == null || length(v.description) <= tonumber(local.metadata.validator_expressions["aws_organizations_policy_description_max_length"])
    ])
    error_message = local.metadata.validator_error_messages["aws_organizations_policy_description_max_length"]
  }

  validation {
    condition = alltrue([
      for k, v in var.policies : can(jsondecode(v.content))
    ])
    error_message = local.metadata.validator_error_messages["aws_organizations_policy_content_json"]
  }

  validation {
    condition = alltrue([
      for k, v in var.policies :
      !contains(["SERVICE_CONTROL_POLICY", "RESOURCE_CONTROL_POLICY"], v.type) ||
      length(v.content) <= tonumber(local.metadata.validator_expressions["aws_organizations_policy_content_size_scp_rcp"])
    ])
    error_message = local.metadata.validator_error_messages["aws_organizations_policy_content_size_scp_rcp"]
  }

  validation {
    condition = alltrue([
      for k, v in var.policies :
      v.type != "AISERVICES_OPT_OUT_POLICY" ||
      length(v.content) <= tonumber(local.metadata.validator_expressions["aws_organizations_policy_content_size_ai_opt_out"])
    ])
    error_message = local.metadata.validator_error_messages["aws_organizations_policy_content_size_ai_opt_out"]
  }

  validation {
    condition = alltrue([
      for k, v in var.policies :
      contains(["SERVICE_CONTROL_POLICY", "RESOURCE_CONTROL_POLICY", "AISERVICES_OPT_OUT_POLICY"], v.type) ||
      length(v.content) <= tonumber(local.metadata.validator_expressions["aws_organizations_policy_content_size_default"])
    ])
    error_message = local.metadata.validator_error_messages["aws_organizations_policy_content_size_default"]
  }
}
