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

# ========================================================================
# SUMMARY OUTPUTS (Enhanced)
# ========================================================================

output "organization_settings_summary" {
  description = "Organization settings configuration summary"
  value = var.mode == "organization" ? {
    name                          = try(github_organization_settings.this[0].name, null)
    billing_email                 = try(github_organization_settings.this[0].billing_email, null)
    default_repository_permission = try(github_organization_settings.this[0].default_repository_permission, null)
    members_can_create_repos      = try(github_organization_settings.this[0].members_can_create_repositories, null)
    members_can_create_pages      = try(github_organization_settings.this[0].members_can_create_pages, null)
    members_can_fork_private      = try(github_organization_settings.this[0].members_can_fork_private_repositories, null)
  } : null
}

output "repositories_summary" {
  description = "Summary statistics of repositories managed by this module"
  value = {
    total = length(module.repo)
    by_visibility = {
      public   = length([for r in module.repo : r if try(r.repository.visibility, "private") == "public"])
      private  = length([for r in module.repo : r if try(r.repository.visibility, "private") == "private"])
      internal = length([for r in module.repo : r if try(r.repository.visibility, "private") == "internal"])
    }
    archived  = length([for r in module.repo : r if try(r.repository.archived, false) == true])
    templates = length([for r in module.repo : r if try(r.repository.is_template, false) == true])
  }
}

output "repositories_security_posture" {
  description = "Security configuration summary across all repositories"
  value = {
    total_repos                          = length(module.repo)
    with_advanced_security               = length([for r in module.repo : r if try(r.security_configuration.advanced_security_enabled, false) == true])
    with_secret_scanning                 = length([for r in module.repo : r if try(r.security_configuration.secret_scanning_enabled, false) == true])
    with_secret_scanning_push_protection = length([for r in module.repo : r if try(r.security_configuration.secret_scanning_push_protection, false) == true])
    with_dependabot_alerts               = length([for r in module.repo : r if try(r.security_configuration.vulnerability_alerts_enabled, false) == true])
    with_dependabot_security_updates     = length([for r in module.repo : r if try(r.security_configuration.dependabot_security_updates, false) == true])
  }
}

output "runner_groups_summary" {
  description = "Summary of runner groups and scale sets deployment"
  value = {
    total_runner_groups    = length(github_actions_runner_group.this)
    groups_with_scale_sets = length([for k, v in var.runner_groups : k if try(v.scale_set, null) != null])
    scale_sets_deployed    = try(module.actions_runner_scale_set[0].scale_set_count, 0)
    total_capacity = {
      min_runners = length(var.runner_groups) > 0 ? sum([for k, v in var.runner_groups : try(v.scale_set.min_runners, 0)]) : 0
      max_runners = length(var.runner_groups) > 0 ? sum([for k, v in var.runner_groups : try(v.scale_set.max_runners, 0)]) : 0
    }
    by_visibility = {
      all      = length([for k, v in github_actions_runner_group.this : k if try(v.visibility, "all") == "all"])
      selected = length([for k, v in github_actions_runner_group.this : k if try(v.visibility, "all") == "selected"])
      private  = length([for k, v in github_actions_runner_group.this : k if try(v.visibility, "all") == "private"])
    }
  }
}

output "governance_summary" {
  description = "Complete governance posture summary"
  value = {
    mode                   = var.mode
    organization           = local.github_org
    plan                   = local.github_plan
    repositories_managed   = length(module.repo)
    runner_groups          = length(github_actions_runner_group.this)
    scale_sets_deployed    = try(module.actions_runner_scale_set[0].scale_set_count, 0)
    organization_webhooks  = length(try(github_organization_webhook.this, {}))
    organization_rulesets  = length(github_organization_ruleset.this)
    custom_roles           = length(github_organization_custom_role.this)
    organization_variables = length(github_actions_organization_variable.this)
    organization_secrets   = length(github_actions_organization_secret.encrypted) + length(github_actions_organization_secret.plaintext)
    dependabot_secrets     = length(github_dependabot_organization_secret.encrypted) + length(github_dependabot_organization_secret.plaintext)
  }
}
