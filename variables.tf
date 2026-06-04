variable "tags" {
  description = "Module-wide tags applied to every policy resource. Merged with metadata tags (lower precedence) and per-policy tags (higher precedence) per ADR-O5."
  type        = map(string)
  default     = {}
}
