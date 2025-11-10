output "organization_id" {
  description = "The ID of the organization"
  value       = module.github_governance.organization_id
}

output "organization_plan" {
  description = "The plan configured for the organization"
  value       = module.github_governance.organization_plan
}

output "repository_ids" {
  description = "Map of repository names to their IDs"
  value       = module.github_governance.repository_ids
}

output "repository_names" {
  description = "Map of repository keys to their actual names"
  value       = module.github_governance.repository_names
}

output "runner_group_ids" {
  description = "Map of runner group names to their IDs"
  value       = module.github_governance.runner_group_ids
}

output "custom_role_ids" {
  description = "Map of custom role names to their IDs (Enterprise only)"
  value       = module.github_governance.custom_role_ids
}

output "ruleset_ids" {
  description = "Map of ruleset names to their IDs (Team+ only)"
  value       = module.github_governance.ruleset_ids
}

output "webhook_ids" {
  description = "Map of webhook names to their IDs"
  value       = module.github_governance.webhook_ids
}

output "features_available" {
  description = "Features available based on current organization plan"
  value       = module.github_governance.features_available
}

output "summary" {
  description = "Summary of created resources"
  value = {
    organization = {
      id   = module.github_governance.organization_id
      plan = module.github_governance.organization_plan
    }
    repositories = {
      count = length(module.github_governance.repository_names)
      names = values(module.github_governance.repository_names)
    }
    runner_groups = {
      count = length(module.github_governance.runner_group_ids)
      names = keys(module.github_governance.runner_group_ids)
    }
    custom_roles = {
      count = length(module.github_governance.custom_role_ids)
      names = keys(module.github_governance.custom_role_ids)
    }
    rulesets = {
      count = length(module.github_governance.ruleset_ids)
      names = keys(module.github_governance.ruleset_ids)
    }
    webhooks = {
      count = length(module.github_governance.webhook_ids)
      names = keys(module.github_governance.webhook_ids)
    }
    features = module.github_governance.features_available
  }
}
