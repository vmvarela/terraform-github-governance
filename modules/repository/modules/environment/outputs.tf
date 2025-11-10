output "environment" {
  description = "Created environment"
  value       = github_repository_environment.this
}

output "deployment_policies" {
  description = "Created deployment policies"
  value       = github_repository_environment_deployment_policy.this
}

output "secrets_plaintext" {
  description = "Created plaintext secrets"
  value       = github_actions_environment_secret.plaintext
}

output "secrets_encrypted" {
  description = "Created encrypted secrets"
  value       = github_actions_environment_secret.encrypted
}

output "variables" {
  description = "Created variables"
  value       = github_actions_environment_variable.this
}
