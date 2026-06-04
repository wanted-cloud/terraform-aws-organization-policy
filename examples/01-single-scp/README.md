# Example 01 — single SCP attached to the org root

This example demonstrates **user story S1** for `terraform-aws-organization-policy`:
author a single Service Control Policy (SCP) and attach it to the organization root,
denying all actions in the `us-east-1` region across every account in the org.

It composes two building-block modules:

- [`terraform-aws-organization`](https://github.com/wanted-cloud/terraform-aws-organization) (T1.01) — bootstraps the AWS Organization, enables the `SERVICE_CONTROL_POLICY` policy type, and exposes `root_id`.
- This module (`terraform-aws-organization-policy`, T1.03) — creates the SCP and binds it to the root via `module.org.root_id`.

The OU building block is not required here — the attachment target is the org root,
which the Organization module surfaces directly.

## Prerequisites

- AWS credentials with `organizations:*` permissions in the management (payer) account.
- Terraform `>= 1.9`.
- The target account must be the organization management account (or empty so the Organization module can bootstrap one).

## Apply

```bash
terraform init
terraform plan
terraform apply
```

On first run the Organization module enables `SERVICE_CONTROL_POLICY` at the root.
This module's precondition then verifies the type is enabled before creating the policy.

## Notes

- Region in `provider "aws"` is `us-east-1` because AWS Organizations is a us-east-1-resident service; any region works for the provider, but `us-east-1` matches the API endpoint.
- The SCP **denies** the region — it does not protect against IAM-permitted access to global services. Read the AWS SCP region-restriction guidance before using in production.

<!-- BEGIN_TF_DOCS -->
Example: single SCP attached to org root.

Demonstrates user story S1 from the T1.03 plan.
Composes 2 modules in this example: terraform-aws-organization (T1.01)
+ this module (T1.03). The OU module is not needed because the attachment
target is the org root, available directly via module.org.root\_id.

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

### <a name="output_attachment_id"></a> [attachment\_id](#output\_attachment\_id)

Description: The created attachment's id (composite policy\_id:target\_id).

### <a name="output_policy_id"></a> [policy\_id](#output\_policy\_id)

Description: The created SCP's AWS-assigned policy id.
<!-- END_TF_DOCS -->
