#
output "organization_settings" {
  description = "Organization settings"
  value       = try(github_organization_settings.this, null)
}

output "repositories" {
  description = "Repositories managed by the module"
  value       = module.repo
}
