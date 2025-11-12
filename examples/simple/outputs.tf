output "organization_id" {
  description = "GitHub organization ID"
  value       = module.github.organization_id
}

output "organization_plan" {
  description = "Current organization plan"
  value       = module.github.organization_plan
}

output "repository_ids" {
  description = "Map of repository names to IDs"
  value       = module.github.repository_ids
}

output "repository_names" {
  description = "Map of repository keys to actual names"
  value       = module.github.repository_names
}

output "runner_group_ids" {
  description = "Map of runner group names to IDs"
  value       = module.github.runner_group_ids
}
