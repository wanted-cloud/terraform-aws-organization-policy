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

variable "attachments" {
  description = <<-EOT
    Map of policy-to-target attachments. Key is a stable, user-chosen identifier
    (typically "<policy_key>_to_<target_short>"). Each entry binds an in-module
    policy (by its var.policies key) to a single target.

    target_id formats:
      - Root:    r-xxxx
      - OU:      ou-xxxx-yyyyyyyy
      - Account: 12-digit AWS account id

    Per-target attachment limits enforced at plan time (override via
    var.metadata.validator_expressions):
      - SCP / RCP / Chatbot / AI-opt-out : 5 per target
      - Tag / Backup                     : 10 per target
  EOT

  type = map(object({
    policy_key = string
    target_id  = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.attachments :
      can(regex(local.metadata.validator_expressions["aws_organizations_policy_attachment_target_id"], v.target_id))
    ])
    error_message = local.metadata.validator_error_messages["aws_organizations_policy_attachment_target_id"]
  }

  validation {
    condition = alltrue([
      for k, v in var.attachments :
      contains(keys(var.policies), v.policy_key)
    ])
    error_message = local.metadata.validator_error_messages["aws_organizations_policy_attachment_policy_key_ref"]
  }

  validation {
    condition = alltrue([
      for pair in distinct([
        for k, v in var.attachments :
        "${v.target_id}|${var.policies[v.policy_key].type}"
        if contains(keys(var.policies), v.policy_key)
      ]) :
      length([
        for k, v in var.attachments : k
        if contains(keys(var.policies), v.policy_key) &&
        "${v.target_id}|${var.policies[v.policy_key].type}" == pair
        ]) <= (
        contains(["TAG_POLICY", "BACKUP_POLICY"], split("|", pair)[1])
        ? tonumber(local.metadata.validator_expressions["aws_organizations_policy_attachment_per_target_per_type_limit_tag_class"])
        : tonumber(local.metadata.validator_expressions["aws_organizations_policy_attachment_per_target_per_type_limit_scp_class"])
      )
    ])
    error_message = "Per-target attachment limit exceeded for one or more (target_id, policy_type) pairs. AWS allows at most ${local.metadata.validator_expressions["aws_organizations_policy_attachment_per_target_per_type_limit_scp_class"]} SCP/RCP/Chatbot/AI-opt-out policies and ${local.metadata.validator_expressions["aws_organizations_policy_attachment_per_target_per_type_limit_tag_class"]} TAG/BACKUP policies attached to a single target."
  }
}
