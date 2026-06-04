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
module "example" {
  source  = "wanted-cloud/organization-policy/aws"
  version = "x.y.z"
}
```

## Contributing

_Contributions are welcomed and must follow [Code of Conduct](https://github.com/wanted-cloud/.github?tab=coc-ov-file) and common [Contributions guidelines](https://github.com/wanted-cloud/.github/blob/main/docs/CONTRIBUTING.md)._

> If you'd like to report security issue please follow [security guidelines](https://github.com/wanted-cloud/.github?tab=security-ov-file).
---
<sup><sub>_2025 &copy; All rights reserved - WANTED.solutions s.r.o._</sub></sup>
<!-- END_TF_DOCS -->