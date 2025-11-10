output "organization_id" {
  description = "The ID of the organization"
  value       = module.github_governance.organization_id
}

output "organization_name" {
  description = "The name of the organization"
  value       = module.github_governance.organization_name
}

output "organization_plan" {
  description = "The plan configured for the organization"
  value       = var.github_plan
}

output "repository_ids" {
  description = "Map of repository names to their IDs"
  value       = module.github_governance.repository_ids
}

output "repository_names" {
  description = "List of all created repository names"
  value       = module.github_governance.repository_names
}

output "repository_urls" {
  description = "Map of repository names to their HTML URLs"
  value       = module.github_governance.repository_html_urls
}

output "runner_group_ids" {
  description = "Map of runner group names to their IDs"
  value       = module.github_governance.runner_group_ids
}

output "runner_group_names" {
  description = "List of all runner group names"
  value       = module.github_governance.runner_group_names
}

output "variable_names" {
  description = "List of organization variable names"
  value       = module.github_governance.variable_names
}

output "secret_names" {
  description = "List of encrypted secret names"
  value       = keys(module.github_governance.secrets_encrypted)
}

output "webhook_urls" {
  description = "Map of webhook names to their URLs"
  value = {
    for name, webhook in module.github_governance.webhooks : name => webhook.url
  }
}

output "custom_role_ids" {
  description = "Map of custom role names to their IDs (Enterprise only)"
  value = var.github_plan == "enterprise" ? {
    for name, role in module.github_governance.custom_roles : name => role.id
  } : {}
}

output "ruleset_ids" {
  description = "Map of ruleset names to their IDs (Team+ only)"
  value = var.github_plan != "free" ? {
    for name, ruleset in module.github_governance.rulesets : name => ruleset.id
  } : {}
}

output "summary" {
  description = "Summary of created resources"
  value = {
    organization = {
      id   = module.github_governance.organization_id
      name = module.github_governance.organization_name
      plan = var.github_plan
    }
    repositories = {
      count = length(module.github_governance.repository_names)
      names = module.github_governance.repository_names
    }
    runner_groups = {
      count = length(module.github_governance.runner_group_names)
      names = module.github_governance.runner_group_names
    }
    variables = {
      count = length(module.github_governance.variable_names)
    }
    secrets = {
      count = length(keys(module.github_governance.secrets_encrypted))
    }
    webhooks = {
      count = length(module.github_governance.webhooks)
    }
    custom_roles = {
      count = var.github_plan == "enterprise" ? length(module.github_governance.custom_roles) : 0
    }
    rulesets = {
      count = var.github_plan != "free" ? length(module.github_governance.rulesets) : 0
    }
  }
}
