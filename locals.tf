locals {
  // Here you can define module metadata
  definitions = {
    tags = {
      ManagedBy             = "Terraform"
      "wanted-cloud:module" = "terraform-aws-organization-policy"
      "wanted-cloud:tier"   = "T1.03"
    }
  }
}
