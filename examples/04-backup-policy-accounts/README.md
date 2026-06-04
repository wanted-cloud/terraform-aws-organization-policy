# Example 04 — backup policy attached to specific account ids

This example demonstrates **user story S4** for `terraform-aws-organization-policy`:
author a single Backup Policy and attach it directly to two specific AWS account ids
(a production account and a security tooling account). Each attachment is a separate
entry in `var.attachments`, sharing the same `policy_key`.

It composes two building-block modules:

- [`terraform-aws-organization`](https://github.com/wanted-cloud/terraform-aws-organization) (T1.01) — bootstraps the AWS Organization and enables the `BACKUP_POLICY` policy type at the root.
- This module (`terraform-aws-organization-policy`, T1.03) — creates the policy and binds it to two account targets.

The OU building block is not required here — both attachment targets are account ids,
which the operator supplies directly. No OU id resolution is needed.

## Why account-level attachments for backup policies

Account-level attachment is a deliberate scoping choice for backup policies in a few
common scenarios:

- **Opt-in coverage.** Some accounts host backup-eligible workloads (databases, data
  lakes, persistent storage); others host only ephemeral compute or sandbox resources.
  Attaching directly to the eligible accounts keeps blast radius narrow and avoids
  authoring per-OU exception logic.
- **Cost predictability.** Backup vault storage, lifecycle transitions, and cross-region
  replication generate costs proportional to the number of accounts the policy applies
  to. Account-level attachment is the most explicit knob for controlling spend.
- **Compliance carve-outs.** Regulated workloads (PCI, HIPAA) often require backup with
  specific retention; non-regulated workloads in adjacent OUs should not inherit the
  same retention by accident. Attaching per-account avoids the inheritance surprise.

When the operator prefers blanket coverage across an OU subtree, attach to the OU
instead — see example 03 (`03-tag-policy-ou-inheritance`) for the inheritance pattern.

## Prerequisites

- AWS credentials with `organizations:*` and `backup:*` permissions in the management (payer) account.
- Terraform `>= 1.9`.
- The target account must be the organization management account (or empty so the Organization module can bootstrap one).
- Replace placeholder account ids (`111111111111`, `222222222222`) with real account ids from your organization before applying.

## Apply

```bash
terraform init
terraform plan
terraform apply
```

On first run the Organization module enables `BACKUP_POLICY` at the root. The
policy module's precondition then verifies the type is enabled before creating
the policy, and both attachments are created in a single apply.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
