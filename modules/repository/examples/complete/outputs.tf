output "repository_name" {
  description = "The name of the repository"
  value       = module.complete_repository.repository.name
}

output "repository_full_name" {
  description = "The full name of the repository (owner/name)"
  value       = module.complete_repository.repository.full_name
}

output "repository_html_url" {
  description = "The URL to the repository on GitHub"
  value       = module.complete_repository.repository.html_url
}

output "repository_ssh_clone_url" {
  description = "The SSH clone URL for the repository"
  value       = module.complete_repository.repository.ssh_clone_url
}

output "repository_http_clone_url" {
  description = "The HTTP clone URL for the repository"
  value       = module.complete_repository.repository.http_clone_url
}

output "deploy_keys" {
  description = "Auto-generated deploy keys (private keys)"
  value       = module.complete_repository.private_keys
  sensitive   = true
}
