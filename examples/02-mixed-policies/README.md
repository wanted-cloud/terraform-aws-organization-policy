# Example 02 — mixed policies (SCP + Tag + Backup) across multiple targets

This example demonstrates **user story S2** for `terraform-aws-organization-policy`:
author three policies of three different types and attach each to a target of a
different class — Service Control Policy to the org root, Tag Policy to an OU,
Backup Policy to a single account. A landing-zone blueprint typically mixes
policy types and target classes this way.

It composes three building-block modules conceptually:

- [`terraform-aws-organization`](https://github.com/wanted-cloud/terraform-aws-organization) (T1.01) — bootstraps the org, enables the three policy types, and exposes `root_id`.
- `terraform-aws-organization-unit` (T1.0X, not yet implemented) — would normally produce the OU id for the Tag Policy attachment. Until that module's outputs interface lands, the OU id is a literal placeholder (`ou-aaaa-bbbbbbbb`). Replace with `module.ou.organizational_units["workloads"].id` once available.
- This module (`terraform-aws-organization-policy`, T1.03) — creates the three policies and binds each to its respective target.

## The `policy_ids_by_type` output

This example surfaces the `policy_ids_by_type` convenience output:

```hcl
output "policies_by_type" {
  value = module.policy.policy_ids_by_type
}
```

The output is a map of `policy_type => list(policy_id)`. Downstream consumers (landing-zone
modules, observability sinks, audit pipelines) can filter or pivot on policy type without
having to know the user-chosen keys passed to `var.policies`. This is the recommended
discovery path whenever the caller cares about "all SCPs" or "all Backup policies" rather
than a specific named policy.

## Prerequisites

- AWS credentials with `organizations:*` permissions in the management (payer) account.
- Terraform `>= 1.9`.
- The target account must be the organization management account (or empty so the Organization module can bootstrap one).
- Replace the OU id placeholder (`ou-aaaa-bbbbbbbb`) and account ids (`111111111111`) with real values from your organization before applying.

## Apply

```bash
terraform init
terraform plan
terraform apply
```

The Organization module enables `SERVICE_CONTROL_POLICY`, `TAG_POLICY`, and `BACKUP_POLICY`
at the org root. The policy module's per-policy precondition then verifies each type is
enabled before creating it.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
