# Example 03 — tag policy attached to an OU (inheritance)

This example demonstrates **user story S3** for `terraform-aws-organization-policy`:
author a tag policy that requires every resource to carry an `Environment` tag
(with one of three allowed values: `production`, `staging`, `development`) and
attach it to an Organizational Unit. AWS Organizations implicitly inherits the
policy to every child account and OU under the target.

It composes three building-block modules **conceptually**:

- [`terraform-aws-organization`](https://github.com/wanted-cloud/terraform-aws-organization) (T1.01) — bootstraps the org and enables the `TAG_POLICY` policy type.
- [`terraform-aws-organization-unit`](https://github.com/wanted-cloud/terraform-aws-organization-unit) (T1.0X, **not yet shipped**) — will eventually provide the OU id via an output.
- This module (`terraform-aws-organization-policy`, T1.03) — creates the tag policy and binds it to the OU.

## OU placeholder

Until the `terraform-aws-organization-unit` module publishes its `organizational_units`
output, the OU id in this example is a **literal placeholder**:

```hcl
# Literal placeholder until terraform-aws-organization-unit ships outputs.
# Replace with: module.ou.organizational_units["workloads"].id
target_id = "ou-aaaa-bbbbbbbb"
```

To use this example today, replace the placeholder with a real OU id from your
organization (look it up via `aws organizations list-organizational-units-for-parent`
or in the AWS Console). Once the OU module ships, swap the literal for the module
reference shown in the comment.

## Tag-policy enforcement model

Tag policies in AWS Organizations are **declarative metadata** — they describe what
tags are required and which values are allowed, but enforcement is performed by the
AWS Resource Groups Tagging API and per-service integrations (here, `ec2:instance`
is enforced via the `enforced_for` field). Resources outside the enforcement list
will be flagged as non-compliant but **not blocked**. Read the AWS tag-policy
documentation before relying on this for hard controls.

## Prerequisites

- AWS credentials with `organizations:*` permissions in the management (payer) account.
- Terraform `>= 1.9`.
- An OU id to attach to (literal until the OU module ships).

## Apply

```bash
terraform init
terraform plan
terraform apply
```

<!-- BEGIN_TF_DOCS -->
Example: tag policy attached to an OU, with implicit inheritance.

Demonstrates user story S3 from the T1.03 plan.
Composes 3 modules conceptually: terraform-aws-organization (T1.01),
terraform-aws-organization-unit (T1.0X, not yet implemented), and this
module (T1.03). Currently the OU module is referenced via a literal
placeholder target\_id — see comment on the attachment target\_id.

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement\_aws) (~> 5.0)

## Providers

No providers.

## Modules

The following Modules are called:

### <a name="module_org"></a> [org](#module\_org)

Source: git::https://github.com/wanted-cloud/terraform-aws-organization.git

Version: main

### <a name="module_policy"></a> [policy](#module\_policy)

Source: ../..

Version:

## Resources

No resources.

## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_policy_arn"></a> [policy\_arn](#output\_policy\_arn)

Description: The created tag policy's ARN.

### <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id)

Description: The created tag policy's AWS-assigned policy id.
<!-- END_TF_DOCS -->
