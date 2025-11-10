output "repositories" {
  description = "Created repositories"
  value       = module.github_governance.repository_names
}

output "runner_groups" {
  description = "Created runner groups"
  value       = module.github_governance.runner_group_ids
}

