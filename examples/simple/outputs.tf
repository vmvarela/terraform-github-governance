# Outputs
output "all_repositories" {
  description = "Full details of all repositories"
  value       = module.governance.repositories
}

output "repository_names" {
  description = "Map of keys to GitHub names"
  value       = module.governance.repository_names
}

output "repository_urls" {
  description = "Map of keys to HTML URLs"
  value       = module.governance.repository_urls
}

output "workspace" {
  description = "The workspace applied to all repositories"
  value       = module.governance.workspace
}

output "organization" {
  description = "The GitHub organization"
  value       = module.governance.organization
}
