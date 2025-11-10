output "id" {
  description = "The ID of the created repository"
  value       = github_repository.this.id
}

output "name" {
  description = "The name of the created repository"
  value       = github_repository.this.name
}

output "full_name" {
  description = "A string of the form 'orgname/reponame'"
  value       = github_repository.this.full_name
}

output "html_url" {
  description = "URL to the repository on the web"
  value       = github_repository.this.html_url
}

output "ssh_clone_url" {
  description = "URL that can be provided to git clone to clone the repository via SSH"
  value       = github_repository.this.ssh_clone_url
}

output "http_clone_url" {
  description = "URL that can be provided to git clone to clone the repository via HTTPS"
  value       = github_repository.this.http_clone_url
}

output "node_id" {
  description = "GraphQL global node id for use with v4 API"
  value       = github_repository.this.node_id
}

output "default_branch" {
  description = "The name of the default branch of the repository"
  value       = coalesce(var.default_branch, "main")
}

output "protected_branches_ruleset_id" {
  description = "ID of the created protected-branches ruleset (if any)"
  value       = length(github_repository_ruleset.ruleset) > 0 ? github_repository_ruleset.ruleset[0].id : null
}

# Configuration outputs (input values for testing)
output "visibility" {
  description = "The visibility of the repository"
  value       = coalesce(var.visibility, "private")
}

output "topics" {
  description = "The topics assigned to the repository"
  value       = var.topics
}

output "properties" {
  description = "The custom properties assigned to the repository"
  value       = var.properties
}

## Removed: no longer echo ruleset input; configuration is flattened.

# Legacy outputs for backward compatibility
output "repository_name" {
  description = "The name of the created repository"
  value       = github_repository.this.name
}

output "repository_id" {
  description = "The ID of the created repository"
  value       = github_repository.this.id
}

output "repository_full_name" {
  description = "A string of the form 'orgname/reponame'"
  value       = github_repository.this.full_name
}

output "deploy_keys_count" {
  description = "Number of deploy keys created"
  value       = length(github_repository_deploy_key.deploy_key)
}

output "webhooks_count" {
  description = "Number of webhooks created"
  value       = length(github_repository_webhook.webhook)
}

output "environments_count" {
  description = "Number of environments created"
  value       = length(github_repository_environment.env)
}

output "protected_branches_ruleset_created" {
  description = "Whether a protected-branches ruleset was created"
  value       = length(github_repository_ruleset.ruleset) > 0
}

output "repository_secrets_count" {
  description = "Number of repository secrets"
  value       = length(github_actions_secret.repo_secret)
}

output "repository_variables_count" {
  description = "Number of repository variables"
  value       = length(github_actions_variable.repo_var)
}

output "properties_count" {
  description = "Number of custom properties created"
  value       = length(github_repository_custom_property.property)
}

output "organization" {
  description = "The GitHub organization name"
  value       = var.organization
}
