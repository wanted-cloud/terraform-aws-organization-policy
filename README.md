# wanted-cloud/terraform-aws-organization-policy

Terraform building block managing AWS Organizations policies and their attachments to root, OUs, or accounts. The module exposes two `for_each` maps — `policies` for authoring (`aws_organizations_policy`) and `attachments` for binding policies to targets (`aws_organizations_policy_attachment`) — and supports all six policy types AWS Organizations ships today: `SERVICE_CONTROL_POLICY`, `TAG_POLICY`, `BACKUP_POLICY`, `AISERVICES_OPT_OUT_POLICY`, `RESOURCE_CONTROL_POLICY`, and `CHATBOT_POLICY`. It composes with `wanted-cloud/terraform-aws-organization` (T1.01, root-only post-split) for the Organization itself and `wanted-cloud/terraform-aws-organization-unit` for OU hierarchy; together the three modules cover the full Tier-1 Organizations surface.

## Table of contents

- [Requirements](#requirements)
- [Providers](#providers)
- [Variables](#inputs)
- [Outputs](#outputs)
- [Resources](#resources)
- [Usage](#usage)
- [3-module composition](#3-module-composition)
- [Tagging](#tagging)
- [Importing existing resources](#importing-existing-resources)
- [Gotchas](#gotchas)
- [Architectural decisions](#architectural-decisions)
- [Failure-mode matrix](#failure-mode-matrix)
- [Examples](#examples)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

<!-- BEGIN_TF_DOCS -->
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
<!-- END_TF_DOCS -->

## Usage

> For more detailed examples navigate to the `examples` folder of this repository.

The module is published via the Terraform Registry and can be consumed directly:

```hcl
module "policy" {
  source  = "wanted-cloud/organization-policy/aws"
  version = "~> 0.1"

  policies = {
    deny_root_user = {
      name    = "DenyRootUser"
      type    = "SERVICE_CONTROL_POLICY"
      content = file("${path.module}/policies/deny-root-user.json")
    }
  }

  attachments = {
    deny_root_to_org_root = {
      policy_key = "deny_root_user"
      target_id  = module.org.id
    }
  }
}
```

### Canonical 3-module composition

The Tier-1 Organizations surface is intentionally split into three small modules. A typical landing zone wires all three together — Organization at the top, OU hierarchy in the middle, policies bound to either:

```hcl
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

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
    "BACKUP_POLICY",
  ]
}

module "ou" {
  source = "git::https://github.com/wanted-cloud/terraform-aws-organization-unit.git?ref=main"

  organizational_units = {
    workloads      = { name = "Workloads", parent_id = module.org.root_id }
    workloads_prod = { name = "Prod", parent_key = "workloads" }
  }
}

module "policy" {
  source = "../.."

  policies = {
    deny_leave_org = {
      name        = "DenyLeaveOrganization"
      type        = "SERVICE_CONTROL_POLICY"
      description = "Prevent member accounts from leaving the Organization."
      content     = file("${path.module}/policies/deny-leave-org.json")
    }
    require_owner_tag = {
      name    = "RequireOwnerTag"
      type    = "TAG_POLICY"
      content = file("${path.module}/policies/require-owner-tag.json")
      tags    = { Scope = "tagging" }
    }
  }

  attachments = {
    deny_leave_to_root = {
      policy_key = "deny_leave_org"
      target_id  = module.org.root_id
    }
    require_owner_to_prod = {
      policy_key = "require_owner_tag"
      target_id  = module.ou.organizational_units["workloads_prod"].id
    }
  }

  tags = {
    Owner = "platform-team"
  }
}
```

## 3-module composition

The dependency flows top-down: the Organization module owns `enabled_policy_types`, which the Policy module reads via `data.aws_organizations_organization.this` and checks against each declared policy in a `lifecycle.precondition`. The OU module is optional — when present it produces `ou-xxxx-yyyyyyyy` ids that callers feed into `attachments[*].target_id`. The Policy module never reaches into the OU module's resources directly; OU ids are passed in by the caller.

```
                 +-----------------------------------------+
                 |  terraform-aws-organization (T1.01)     |
                 |  aws_organizations_organization.this    |
                 |    outputs: id, root_id,                |
                 |             enabled_policy_types        |
                 +-----------+-----------------+-----------+
                             |                 |
                             |                 | (root_id, enabled_policy_types)
                             |                 |
              (root_id)      |                 v
                             |     +-----------------------------+
                             |     | terraform-aws-org-policy    |
                             |     | (this module — T1.03)       |
                             |     |   data.aws_organizations_   |
                             |     |       organization.this     |
                             |     |   lifecycle.precondition    |
                             v     |     enabled_policy_types    |
              +--------------+--+  |   aws_organizations_policy  |
              | terraform-aws-  |  |   aws_organizations_policy_ |
              | organization-   |  |       attachment            |
              | unit (T1.x)     |  +---------------+-------------+
              |   outputs: id   |                  |
              +--------+--------+                  |
                       |                           |
                       |   (ou-xxxx-yyyyyyyy ids)  |
                       +-------------------------->+
                                                   |
                                                   v
                                  attachments[*].target_id =
                                    root id | OU id | account id
```

The arrows are caller-mediated — there is no provider-level coupling between the three modules. They can be applied independently, versioned independently, and adopted incrementally.

## Tagging

Tags are mandatory and applied **inline** on `aws_organizations_policy` via the resource's `tags` argument. The module computes them at apply time as:

```hcl
tags = merge(local.metadata.tags, var.tags, each.value.tags)
```

The merge precedence (lowest → highest, later wins):

1. `local.definitions.tags` — identity tags the module always emits (`ManagedBy = "Terraform"`, `wanted-cloud:module = "terraform-aws-organization-policy"`, `wanted-cloud:tier = "T1.03"`). Override via `var.metadata.tags`.
2. `var.metadata.tags` — caller overrides for identity/governance tags.
3. `var.tags` — module-wide tags applied to every policy.
4. `each.value.tags` — per-policy tags supplied inside `var.policies[k].tags`.

The attachment resource (`aws_organizations_policy_attachment`) does not accept tags in the AWS provider schema — only the policy resource is tagged.

> **Warning:** Do NOT use `aws_organizations_tag` alongside this module. The inline `tags` argument on `aws_organizations_policy` and the separate `aws_organizations_tag` resource will both try to own the tag set, producing perpetual `terraform plan` diffs as each surface re-reconciles on every apply. The AWS provider documentation suggests `lifecycle.ignore_changes = [tags]` as a workaround when the two are mixed, but this module's canonical stance is "use only the inline path." If existing infrastructure already uses `aws_organizations_tag`, migrate the tags inline and remove the separate resource before adopting this module.

## Importing existing resources

The module supports importing pre-existing AWS Organizations policies and attachments — typical when policies were created via the AWS console, Control Tower, or an earlier non-Terraform automation.

### Importing a policy

Policy import keys are AWS policy IDs in the form `p-` followed by 8+ alphanumeric characters (e.g. `p-abcdef12`):

```bash
terraform import 'module.policy.aws_organizations_policy.this["deny_root_user"]' p-abcdef12
```

The key inside the brackets (`"deny_root_user"`) must match the key under which you've declared the policy in `var.policies`. The 12-character-ish id on the right is the AWS-assigned policy ID, visible in the console and in `aws organizations list-policies --filter SERVICE_CONTROL_POLICY` output.

### Importing an attachment

Attachment import keys are composite: `<policy_id>:<target_id>` (colon-separated, policy id first):

```bash
terraform import 'module.policy.aws_organizations_policy_attachment.this["deny_root_to_org_root"]' p-abcdef12:r-a1b2
```

The same rules apply on the left side — the key inside the brackets must match the key in `var.attachments`. The composite right-hand side joins the policy ID with the target ID (root, OU, or account).

### Verifying the import

After importing, run `terraform plan`. If the imported state matches the declared HCL, the plan reports **No changes**. If the plan proposes updates, reconcile field-by-field — common drift sources are tag set differences (the live policy may carry tags not declared in HCL) and minor whitespace/JSON-canonicalization differences in `content`. Tags in particular: a clean import expects the live tag set to equal `merge(local.metadata.tags, var.tags, each.value.tags)`. If it differs, either align the HCL tags or accept the drift via a one-shot apply.

## Gotchas

Read these before applying to any Organization that matters.

| # | Symptom | Cause | Fix |
|---|---|---|---|
| 1 | `terraform plan` fails with "Policy type X is not enabled at the AWS Organization root" | T1.01's `enabled_policy_types` doesn't include the requested type — the `lifecycle.precondition` in this module catches it before AWS does | Add the type to T1.01's `var.enabled_policy_types` and re-apply T1.01 before applying this module. |
| 2 | `AWSOrganizationsLimitExceededException: per-target attachment limit` at apply | More than 5 SCP/RCP/Chatbot/AI-opt-out, or 10 Tag/Backup policies attached to the same target | The plan-time validator catches this for module-managed attachments. For out-of-band attachments (Control Tower, console), inspect the target with `aws organizations list-policies-for-target` and detach unused policies first. |
| 3 | `MalformedPolicyDocument` at apply | Policy JSON is syntactically valid but semantically wrong (e.g. invalid action name, malformed `Condition`, wrong resource ARN shape) | Validate the JSON against the AWS Policy Validator or by trial-attaching via the AWS console first — this module performs structural JSON validation only (`jsondecode`), not semantic validation. |
| 4 | Service-name principals in SCPs not matching anything at runtime | SCP service principals are case-sensitive — `s3.amazonaws.com` works, `S3.amazonaws.com` is silently ignored | Lowercase all service principals in your policy documents. |
| 5 | Tag policy evaluates as "compliant" with no enforcement happening | Tag policies declare requirements but enforcement is the Resource Groups Tagging API's job, not this module's | Configure tag-policy enforcement at the OU/account level via the AWS console (Tag Policies → Enforcement settings) or a future tagging-compliance module. |
| 6 | Backup policies reference vaults that don't exist | Backup policies refer to vault names that must pre-exist in the target accounts — they're not created transitively | Create the backup vaults out-of-band (or via a future `terraform-aws-backup-vault` module) in the target accounts before activating the backup plan. |
| 7 | `terraform destroy` of a policy fails with `PolicyInUseException` | Someone (Console, Control Tower, another automation) attached this module-managed policy to a target out-of-band; destroy cannot proceed while the policy has live attachments | Detach the out-of-band attachment manually in the AWS console, then `terraform destroy` again. ADR-O4 relies on the dependency graph for module-managed attachments, but it cannot see out-of-band ones. |
| 8 | Imported attachment shows diff on the next `terraform plan` | Composite import key was entered with the wrong format (missing colon, wrong order, or extra whitespace) | Re-import using `<policy_id>:<target_id>` — colon-separated, policy ID first. Verify with `terraform plan` showing **No changes**. |
| 9 | `RESOURCE_CONTROL_POLICY` and `CHATBOT_POLICY` rejected at apply despite being declared in T1.01's `enabled_policy_types` | These are newer policy types (2024 GA); availability depends on region and Organization age | Confirm enablement with `aws organizations describe-enabled-policy-types --target-id <root-id>`. Older Organizations may need AWS Support to enable RCP explicitly. |
| 10 | Mixing inline `tags` with `aws_organizations_tag` resources causes perpetual `terraform plan` diffs | Both surfaces try to own the tag set; AWS returns the union, Terraform reconciles each separately | This module ships only the inline `tags` path. Do not combine with `aws_organizations_tag` separately. If you must mix, add `lifecycle.ignore_changes = [tags]` on the policy — but the cleanest path is to pick one surface and stick with it. |

## Architectural decisions

ADRs are tracked in the implementation plan; this table summarizes the seven that shape the v0.1 surface.

| ADR | Decision | Rationale |
|---|---|---|
| O1 | Attachments reference policies by in-module `policy_key` only | Eliminates a class of typos (caller had to remember AWS-generated `p-...` ids) and lets the validator catch dangling references at plan time. |
| O2 | BYO `policy_ids` deferred to v0.2 via XOR field | Keeps the v0.1 surface small. v0.2 will add `policy_id_external` alongside `policy_key`, mutually exclusive per attachment. |
| O3 | `data "aws_organizations_organization" "this"` + `lifecycle.precondition` enforces enabled-type check at plan time | Surfaces the most common misconfiguration (forgot to enable the type on T1.01) with an actionable message before reaching AWS. |
| O4 | Rely on Terraform's dependency graph for destroy ordering | The implicit dependency from `aws_organizations_policy_attachment.policy_id` to `aws_organizations_policy.id` orders apply (policy first) and destroy (attachment first) correctly. Out-of-band attachments are documented as Gotcha #7. |
| O5 | Tag merge precedence: `definitions.tags < metadata.tags < var.tags < each.value.tags` | Identity tags ship as defaults, callers override via `var.metadata.tags`, module-wide governance via `var.tags`, per-policy specifics via `each.value.tags`. Mirrors the wanted-cloud Azure modules' tag-merging conventions. |
| O6 | Default timeouts 30m / 5m / 30m / 30m | Mirrors the canonical wanted-cloud Azure default and gives Organizations API enough headroom for slow regions. Surfaced via `var.metadata.resource_timeouts` even though the policy resources don't accept a `timeouts {}` block in AWS provider v5.x (kept for cross-module consistency). |
| O7 | Ship 10 of 12 candidate gotchas in v0.1 README | The two deferred gotchas (provider-version pinning quirks; cross-region attachment latency) are uncommon enough to ship with v0.2 once real-AWS integration tests have validated them. |

## Failure-mode matrix

The module documents 17 failure modes across three categories. The plan-time set is enforced by validators or preconditions before any AWS API call; the AWS API error set is documented but not preventable from HCL; the silent set is out of scope for v0.1.

### Plan-time (caught by validators or preconditions — 8 modes)

| # | Mode | Surface |
|---|---|---|
| 1 | Unknown `policy.type` value | `var.policies` validator (`aws_organizations_policy_type`) |
| 2 | Invalid `policy.name` (length or charset) | `var.policies` validator (`aws_organizations_policy_name`) |
| 3 | `policy.description` longer than 512 chars | `var.policies` validator (`aws_organizations_policy_description_max_length`) |
| 4 | `policy.content` not valid JSON | `var.policies` validator (`aws_organizations_policy_content_json`) |
| 5 | `policy.content` exceeds per-type size limit (5120 / 2500 / 10000) | `var.policies` validators (`aws_organizations_policy_content_size_*`) |
| 6 | `attachment.target_id` not a root/OU/account id | `var.attachments` validator (`aws_organizations_policy_attachment_target_id`) |
| 7 | `attachment.policy_key` references a missing `var.policies` key | `var.attachments` validator (`aws_organizations_policy_attachment_policy_key_ref`) |
| 8 | Per-target/per-type attachment count exceeded (>5 SCP-class or >10 Tag-class) | `var.attachments` validator (`aws_organizations_policy_attachment_per_target_per_type_limit_*`); also `lifecycle.precondition` for policy-type-enablement |

### AWS API error (documented, surfaced at apply — 7 modes)

| # | Mode | AWS error |
|---|---|---|
| 9 | Policy type not enabled on the Organization root | `PolicyTypeNotEnabledException` — also caught by precondition at plan time when T1.01 outputs are in scope |
| 10 | Per-target attachment limit exceeded by an out-of-band attachment | `LimitExceededException` (Organizations service) |
| 11 | Policy JSON semantically invalid (bad action, bad resource ARN) | `MalformedPolicyDocumentException` |
| 12 | Destroy blocked by out-of-band attachment | `PolicyInUseException` |
| 13 | Newer policy type (RCP, Chatbot) not yet available in the Organization | `PolicyTypeNotAvailableForOrganizationException` |
| 14 | Duplicate policy name within the Organization | `DuplicatePolicyException` |
| 15 | Target not found (OU deleted, account closed) | `TargetNotFoundException` |

### Silent / out-of-scope (2 modes)

Tag-policy compliance and backup-vault existence are out of scope. Tag policies declare requirements but rely on the Resource Groups Tagging API for enforcement (Gotcha #5); backup policies require pre-existing vaults in the target accounts (Gotcha #6). Neither failure surfaces as a Terraform error — the apply succeeds, but runtime behaviour is silently degraded. Both are deferred to companion modules.

## Examples

Worked examples live under [`./examples/`](./examples/). Each example wires the canonical three modules — Organization, OU, Policy — and exercises a specific story.

- [`./examples/01-single-scp/`](./examples/01-single-scp/) — minimal: one `SERVICE_CONTROL_POLICY` attached to the Organization root. Story S1.
- [`./examples/02-mixed-policies/`](./examples/02-mixed-policies/) — multiple policies of different types (`SCP` + `TAG_POLICY` + `BACKUP_POLICY`) attached across the root, an OU, and a member account. Story S2.
- [`./examples/03-tag-policy-ou-inheritance/`](./examples/03-tag-policy-ou-inheritance/) — single `TAG_POLICY` attached to a parent OU; child accounts inherit it. Story S3.
- [`./examples/04-backup-policy-accounts/`](./examples/04-backup-policy-accounts/) — `BACKUP_POLICY` attached directly to two member account ids. Story S4.

## Roadmap

- Advanced examples covering Stories S5 (import workflow with `moved {}` blocks), S6 (removal safety in the face of out-of-band attachments), S7 (per-target limit violation behaviour), and S8 (precondition-failure walkthrough). Deferred to v0.2.
- `DECLARATIVE_POLICY_EC2` policy type support — deferred until consumer demand emerges and the AWS provider's surface stabilizes.
- Real-AWS integration tests against a shared `wanted-cloud-test-org` sandbox. Tracked as a Tier-2 roadmap item; currently the module is validated via `terraform validate` and worked examples only.

## Contributing

_Contributions are welcomed and must follow the [Code of Conduct](https://github.com/wanted-cloud/.github?tab=coc-ov-file) and common [Contributions guidelines](https://github.com/wanted-cloud/.github/blob/main/docs/CONTRIBUTING.md)._

> If you'd like to report a security issue please follow the [security guidelines](https://github.com/wanted-cloud/.github?tab=security-ov-file).

---
<sup><sub>_2025 &copy; All rights reserved - WANTED.solutions s.r.o._</sub></sup>
