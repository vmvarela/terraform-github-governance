output "all_repositories" {
  description = "Full details of all repositories"
  value       = module.governance.repositories
}

output "renamed_repository" {
  description = "Example of renamed repository - key vs actual name"
  value = {
    terraform_key = "legacy-auth"
    github_name   = module.governance.repository_names["legacy-auth"]
    github_url    = module.governance.repository_urls["legacy-auth"]
  }
}

output "repository_names" {
  description = "Map of keys to GitHub names"
  value       = module.governance.repository_names
}

output "repository_urls" {
  description = "Map of keys to HTML URLs"
  value       = module.governance.repository_urls
}

output "templated_repository" {
  description = "Repository created from template"
  value = {
    name         = module.governance.repository_names["new-service"]
    created_from = "service-template"
  }
}

output "workspace" {
  description = "The workspace applied to all repositories"
  value       = module.governance.workspace
}
