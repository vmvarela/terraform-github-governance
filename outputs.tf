output "organization" {
  description = "The GitHub organization name."
  value       = var.organization
}

output "repositories" {
  description = "Map of repository keys to their full output details from the repository module."
  value = {
    for key, repo in module.repositories :
    key => {
      id                            = repo.id
      name                          = repo.name
      full_name                     = repo.full_name
      html_url                      = repo.html_url
      ssh_clone_url                 = repo.ssh_clone_url
      http_clone_url                = repo.http_clone_url
      node_id                       = repo.node_id
      default_branch                = repo.default_branch
      protected_branches_ruleset_id = repo.protected_branches_ruleset_id
      applied_preset                = local.processed_repositories[key].preset_name
    }
  }
}

output "repository_names" {
  description = "Map of repository keys to their GitHub names."
  value = {
    for key, repo in module.repositories :
    key => repo.name
  }
}

output "repository_urls" {
  description = "Map of repository keys to their HTML URLs."
  value = {
    for key, repo in module.repositories :
    key => repo.html_url
  }
}

output "workspace" {
  description = "The workspace name applied to all repositories."
  value       = var.workspace
}
