#
output "organization_settings" {
  description = "Organization settings"
  value       = try(github_organization_settings.this, null)
}

output "organization_plan" {
  description = "Current GitHub organization plan (free, team, business, enterprise)"
  value       = local.github_plan
}

output "organization_id" {
  description = "GitHub organization ID"
  value       = try(local.info_organization.id, null)
}

output "repositories" {
  description = "Repositories managed by the module (complete module outputs)"
  value       = module.repo
}

output "repository_ids" {
  description = <<-EOT
    Map of all repository names to their IDs (numeric).
    Includes both repositories managed by this module and existing repositories in the organization.
    Useful for referencing repositories in rulesets, runner groups, and other resources.

    Usage example in rulesets:
      selected_repository_ids = [
        module.github.repository_ids["my-repo"],
        module.github.repository_ids["another-repo"]
      ]
  EOT
  value       = local.github_repository_id
}

output "repository_names" {
  description = "Map of repository keys to their actual names (after applying spec formatting)"
  value = {
    for key, repo in module.repo : key => repo.repository.name
  }
}

output "runner_group_ids" {
  description = "Map of runner group names to their IDs"
  value = {
    for name, rg in github_actions_runner_group.this : name => rg.id
  }
}

output "custom_role_ids" {
  description = "Map of custom repository role names to their IDs (Enterprise only)"
  value = {
    for name, role in github_organization_custom_role.this : name => role.id
  }
}

output "ruleset_ids" {
  description = "Map of organization ruleset names to their IDs"
  value = {
    for name, rs in github_organization_ruleset.this : name => rs.id
  }
}

output "webhook_ids" {
  description = "Map of organization webhook names to their IDs"
  value = {
    for name, wh in try(github_organization_webhook.this, {}) : name => wh.id
  }
}

output "features_available" {
  description = "Features available based on current organization plan"
  value = {
    webhooks          = contains(["team", "business", "enterprise"], local.github_plan)
    custom_roles      = contains(["enterprise"], local.github_plan)
    rulesets          = contains(["team", "business", "enterprise"], local.github_plan)
    internal_repos    = contains(["business", "enterprise"], local.github_plan)
    saml_sso          = contains(["business", "enterprise"], local.github_plan)
    advanced_security = contains(["enterprise"], local.github_plan)
  }
}
