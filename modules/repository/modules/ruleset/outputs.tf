# ========================================================================
# LEGACY OUTPUTS (Maintained for backwards compatibility)
# ========================================================================

output "ruleset" {
  description = "Complete ruleset object (use specific outputs for better terraform graph performance)"
  value       = github_repository_ruleset.this
}

# ========================================================================
# RULESET BASIC OUTPUTS
# ========================================================================

output "id" {
  description = "Numeric ID of the ruleset"
  value       = github_repository_ruleset.this.id
}

output "name" {
  description = "Name of the ruleset"
  value       = github_repository_ruleset.this.name
}

output "enforcement" {
  description = "Enforcement level (disabled, active, evaluate)"
  value       = github_repository_ruleset.this.enforcement
}

output "target" {
  description = "Target of the ruleset (branch, tag, push)"
  value       = github_repository_ruleset.this.target
}

output "node_id" {
  description = "GraphQL global node ID of the ruleset"
  value       = github_repository_ruleset.this.node_id
}

output "etag" {
  description = "ETag of the ruleset"
  value       = github_repository_ruleset.this.etag
}
