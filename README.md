<!-- BEGIN_TF_DOCS -->
# wanted-cloud/terraform-aws-organization-policy

Terraform building block managing AWS Organizations policies and their attachments to root, OUs, or accounts.

## Table of contents

- [Requirements](#requirements)
- [Providers](#providers)
- [Variables](#inputs)
- [Outputs](#outputs)
- [Resources](#resources)
- [Usage](#usage)
- [Importing existing resources](#importing-existing-resources)
- [Gotchas](#gotchas)
- [Contributing](#contributing)

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (~> 5.0)

## Providers

The following providers are used by this module:

- <a name="provider_aws"></a> [aws](#provider\_aws) (5.100.0)

## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_attachments"></a> [attachments](#input\_attachments)

Description: Map of policy-to-target attachments. Key is a stable, user-chosen identifier
(typically "<policy\_key>\_to\_<target\_short>"). Each entry binds an in-module  
policy (by its var.policies key) to a single target.

target\_id formats:
  - Root:    r-xxxx
  - OU:      ou-xxxx-yyyyyyyy
  - Account: 12-digit AWS account id

Per-target attachment limits enforced at plan time (override via  
var.metadata.validator\_expressions):
  - SCP / RCP / Chatbot / AI-opt-out : 5 per target
  - Tag / Backup                     : 10 per target

Type:

```hcl
map(object({
    policy_key = string
    target_id  = string
  }))
```

Default: `{}`

### <a name="input_metadata"></a> [metadata](#input\_metadata)

Description: Metadata definitions for the module, this is optional construct allowing override of the module defaults defintions of validation expressions, error messages, resource timeouts and default tags.

Type:

```hcl
object({
    resource_timeouts = optional(
      map(
        object({
          create = optional(string, "30m")
          read   = optional(string, "5m")
          update = optional(string, "30m")
          delete = optional(string, "30m")
        })
      ), {}
    )
    tags                     = optional(map(string), {})
    validator_error_messages = optional(map(string), {})
    validator_expressions    = optional(map(string), {})
  })
```

Default: `{}`

### <a name="input_policies"></a> [policies](#input\_policies)

Description: Map of AWS Organizations policies to author. Key is a stable, user-chosen  
identifier referenced by var.attachments[*].policy\_key. Each entry defines  
a policy by type, name, content, optional description, and optional tags.

Policy `content` is a JSON string — typically produced via file("./scp.json"),  
jsonencode({...}), or heredoc. Per-type content size limits enforced at plan  
time (override via var.metadata.validator\_expressions):
  - SERVICE\_CONTROL\_POLICY    / RESOURCE\_CONTROL\_POLICY : 5120 bytes
  - AISERVICES\_OPT\_OUT\_POLICY                            : 2500 bytes
  - TAG\_POLICY / BACKUP\_POLICY / CHATBOT\_POLICY          : 10000 bytes

Type:

```hcl
map(object({
    name        = string
    type        = string
    content     = string
    description = optional(string, null)
    tags        = optional(map(string), {})
  }))
```

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Module-wide tags applied to every policy resource. Merged with metadata tags (lower precedence) and per-policy tags (higher precedence) per ADR-O5.

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_attachments"></a> [attachments](#output\_attachments)

Description: Map of created policy attachments, keyed by the user's var.attachments key. Each entry exposes the AWS-assigned attachment id, the resolved policy\_id, the target\_id, and a pass-through of the policy\_key for traceability.

### <a name="output_policies"></a> [policies](#output\_policies)

Description: Map of created policies, keyed by the user's var.policies key. Each entry exposes the AWS-assigned id, arn, plus pass-through of name, type, and description for convenient referencing in downstream modules.

### <a name="output_policy_ids_by_key"></a> [policy\_ids\_by\_key](#output\_policy\_ids\_by\_key)

Description: Convenience output: map of user-chosen var.policies key => created policy id. Equivalent to a one-field projection of the full policies output; useful when downstream code only needs the id.

### <a name="output_policy_ids_by_type"></a> [policy\_ids\_by\_type](#output\_policy\_ids\_by\_type)

Description: Convenience output: map of policy\_type => list of created policy IDs. Lets downstream modules discover policies by AWS type without knowing the user's for\_each keys. Useful when composing into landing-zone blueprints that filter by type.

## Resources

The following resources are used by this module:

- [aws_organizations_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy) (resource)
- [aws_organizations_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) (resource)
- [aws_organizations_organization.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) (data source)

## Usage

> For more detailed examples navigate to `examples` folder of this repository.

Module was also published via Terraform Registry and can be used as a module from the registry.

```hcl
module "policy" {
  source  = "wanted-cloud/organization-policy/aws"
  version = "~> 0.1"

  policies = {
    deny_us_east_1 = {
      name = "deny_us_east_1"
      type = "SERVICE_CONTROL_POLICY"
      content = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Deny"
          Action    = "*"
          Resource  = "*"
          Condition = { StringEquals = { "aws:RequestedRegion" = "us-east-1" } }
        }]
      })
    }
  }

  attachments = {
    deny_us_east_1_to_root = {
      policy_key = "deny_us_east_1"
      target_id  = "r-xxxx"
    }
  }
}
```

### Minimal — single SCP attached to root

```hcl
/*
 * Example: single SCP attached to org root.
 *
 * Demonstrates user story S1 from the T1.03 plan.
 * Composes 2 modules in this example: terraform-aws-organization (T1.01)
 * + this module (T1.03). The OU module is not needed because the attachment
 * target is the org root, available directly via module.org.root_id.
 */

module "org" {
  source = "git::https://github.com/wanted-cloud/terraform-aws-organization.git?ref=main"

  feature_set          = "ALL"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

module "policy" {
  source = "../.."

  policies = {
    deny_us_east_1 = {
      name = "deny_us_east_1"
      type = "SERVICE_CONTROL_POLICY"
      content = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid      = "DenyUsEast1"
          Effect   = "Deny"
          Action   = "*"
          Resource = "*"
          Condition = {
            StringEquals = {
              "aws:RequestedRegion" = "us-east-1"
            }
          }
        }]
      })
      description = "Denies all actions in us-east-1 across the org."
    }
  }

  attachments = {
    deny_us_east_1_to_root = {
      policy_key = "deny_us_east_1"
      target_id  = module.org.root_id
    }
  }
}
```

## Importing existing resources

When a policy or its attachment already exists in the Organization, import it before the first `terraform apply`:

```bash
terraform import 'module.policy.aws_organizations_policy.this["scp_baseline"]' p-abcdef12
terraform import 'module.policy.aws_organizations_policy_attachment.this["scp_baseline_to_root"]' p-abcdef12:r-xxxx
```

The policy import key is the 8-character AWS policy id (`p-xxxxxxxx`). The attachment import key is `policy_id:target_id` (colon-separated, policy first). After import, run `terraform plan` and reconcile any drift in `content`, `description`, or `tags`.

## Gotchas

Read these before applying in any organization that matters.

| # | Gotcha | Mitigation |
|---|---|---|
| 1 | **Policy type must be enabled at the org root** before any policy of that type can be attached. | T1.01 (`terraform-aws-organization`) owns `enabled_policy_types`. The module surfaces a plan-time precondition error pointing at T1.01. |
| 2 | **Per-target attachment limits**: max 5 SCP/RCP/Chatbot/AI-opt-out per target, max 10 Tag/Backup. | The `var.attachments` validator catches module-managed overruns at plan time; out-of-band attachments (Control Tower, console) can still push real AWS state over. |
| 3 | **Policy content size limits differ per type**: 5,120 bytes (SCP/RCP), 2,500 (AI opt-out), 10,000 (Tag/Backup/Chatbot). | Per-type size validators fail at plan time with the specific cap quoted. |
| 4 | **Default `FullAWSAccess` SCP is attached to every OU/account.** Removing it (e.g. via a deny-all SCP without an allow path) locks the OU out of every AWS service. | The module does not touch `FullAWSAccess`. Use deny-only SCPs only with caution and never on the management account. |
| 5 | **Declarative policies (Tag/Backup/AI-opt-out) apply to the management account too** — SCP and RCP are the only exceptions. | A tag policy attached to root will hit the management account. Validate scope before attaching to root. |
| 6 | **Destroying a policy fails while attachments exist (`PolicyInUseException`)**. Module-managed attachments destroy first via the dependency graph; out-of-band attachments block destroy. | Use `aws organizations list-targets-for-policy` to find out-of-band attachments before destroy. |
| 7 | **Policy JSON is not validated semantically** — syntactically valid but logically wrong policies apply cleanly and break things. | Use `aws organizations describe-effective-policy` after apply, or test in a sandbox OU first. |
| 8 | **OU/account attachments inherit downward** — a tag policy on `ou-workloads` hits every child account. You cannot re-attach per child. | This is AWS-side behavior, not module behavior; design OU hierarchy accordingly. |
| 9 | **Backup policy JSON may reference vaults that live in other accounts** — the module does not own those resources. | Ensure referenced vaults exist before the policy triggers; failures surface at backup runtime, not at apply. |
| 10 | **Do NOT use `aws_organizations_tag` alongside this module's inline `tags` argument.** Both surfaces try to own tags → perpetual `terraform plan` diff. | This module ships only inline `tags`. If mixing is unavoidable, add `lifecycle.ignore_changes = [tags]` on the parent — but pick one path. |

## Contributing

_Contributions are welcomed and must follow [Code of Conduct](https://github.com/wanted-cloud/.github?tab=coc-ov-file) and common [Contributions guidelines](https://github.com/wanted-cloud/.github/blob/main/docs/CONTRIBUTING.md)._

> If you'd like to report security issue please follow [security guidelines](https://github.com/wanted-cloud/.github?tab=security-ov-file).
---
<sup><sub>_2025 &copy; All rights reserved - WANTED.solutions s.r.o._</sub></sup>
<!-- END_TF_DOCS -->
