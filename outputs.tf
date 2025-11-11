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
  description = "Repositories managed by the module (complete repository objects)"
  value       = github_repository.repo
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
    for key, repo in github_repository.repo : key => repo.name
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
    total = length(github_repository.repo)
    by_visibility = {
      public   = length([for r in github_repository.repo : r if try(r.visibility, "private") == "public"])
      private  = length([for r in github_repository.repo : r if try(r.visibility, "private") == "private"])
      internal = length([for r in github_repository.repo : r if try(r.visibility, "private") == "internal"])
    }
    archived  = length([for r in github_repository.repo : r if try(r.archived, false) == true])
    templates = length([for r in github_repository.repo : r if try(r.is_template, false) == true])
  }
}

output "repositories_security_posture" {
  description = "Security configuration summary across all repositories"
  value = {
    total_repos                          = length(github_repository.repo)
    with_advanced_security               = length([for r in github_repository.repo : r if try(r.security_and_analysis[0].advanced_security[0].status, "disabled") == "enabled"])
    with_secret_scanning                 = length([for r in github_repository.repo : r if try(r.security_and_analysis[0].secret_scanning[0].status, "disabled") == "enabled"])
    with_secret_scanning_push_protection = length([for r in github_repository.repo : r if try(r.security_and_analysis[0].secret_scanning_push_protection[0].status, "disabled") == "enabled"])
    with_dependabot_alerts               = length([for r in github_repository.repo : r if try(r.vulnerability_alerts, false) == true])
    with_dependabot_security_updates     = length([for k, v in github_repository_dependabot_security_updates.repo : k if try(v.enabled, false) == true])
  }
}

output "runner_groups_summary" {
  description = "Summary of runner groups configuration"
  value = {
    total_runner_groups = length(github_actions_runner_group.this)
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
    repositories_managed   = length(github_repository.repo)
    runner_groups          = length(github_actions_runner_group.this)
    organization_webhooks  = length(try(github_organization_webhook.this, {}))
    organization_rulesets  = length(github_organization_ruleset.this)
    custom_roles           = length(github_organization_custom_role.this)
    organization_variables = length(github_actions_organization_variable.this)
    organization_secrets   = length(github_actions_organization_secret.encrypted) + length(github_actions_organization_secret.plaintext)
    dependabot_secrets     = length(github_dependabot_organization_secret.encrypted) + length(github_dependabot_organization_secret.plaintext)
  }
}
