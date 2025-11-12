# ============================================================================
# SUMMARY OUTPUTS
# ============================================================================

output "organization_name" {
  description = "GitHub organization being managed"
  value       = var.organization_name
}

output "total_repositories" {
  description = "Total number of repositories managed"
  value       = module.github_org.repositories_summary.total
}

output "repositories_by_visibility" {
  description = "Repository count by visibility (public/private/internal)"
  value       = module.github_org.repositories_summary.by_visibility
}

output "repositories_by_team" {
  description = "Repository count by primary team/domain"
  value = {
    backend  = length([for k in keys(module.github_org.repositories) : k if can(regex("^backend-", k))])
    frontend = length([for k in keys(module.github_org.repositories) : k if can(regex("^frontend-", k))])
    infra    = length([for k in keys(module.github_org.repositories) : k if can(regex("^infra-", k))])
    data     = length([for k in keys(module.github_org.repositories) : k if can(regex("^data-", k))])
    mobile   = length([for k in keys(module.github_org.repositories) : k if can(regex("^mobile-", k))])
    docs     = length([for k in keys(module.github_org.repositories) : k if contains(["public-docs", ".github", "security-policy", "engineering-handbook"], k)])
  }
}

# ============================================================================
# SECURITY OUTPUTS
# ============================================================================

output "security_posture" {
  description = "Security features status across all repositories"
  value       = module.github_org.repositories_security_posture
}

output "repositories_with_vulnerability_alerts" {
  description = "Number of repositories with vulnerability alerts enabled"
  value = length([
    for k, r in module.github_org.repositories :
    k if try(r.vulnerability_alerts, false)
  ])
}

output "repositories_with_dependabot" {
  description = "Number of repositories with Dependabot security updates enabled"
  value = length([
    for k, r in module.github_org.repositories :
    k if try(r.dependabot_security_updates, false)
  ])
}

output "repositories_with_secret_scanning" {
  description = "Number of repositories with secret scanning enabled"
  value = length([
    for k, r in module.github_org.repositories :
    k if try(r.secret_scanning, false)
  ])
}

# ============================================================================
# COMPLIANCE OUTPUTS
# ============================================================================

output "organization_rulesets" {
  description = "Organization-wide rulesets enforcing compliance"
  value = {
    total = length(module.github_org.ruleset_ids)
    rulesets = {
      main_branch_protection = try(module.github_org.ruleset_ids["main-branch-protection"], null)
      conventional_commits   = try(module.github_org.ruleset_ids["conventional-commits"], null)
      release_protection     = try(module.github_org.ruleset_ids["release-branch-protection"], null)
      tag_protection         = try(module.github_org.ruleset_ids["semver-tags"], null)
    }
  }
}

output "protected_branches_count" {
  description = "Estimated number of branches protected by organization rulesets"
  value = {
    main_branches    = module.github_org.repositories_summary.total # All repos have main protected
    release_branches = "dynamic"                                    # Depends on active release branches
    all_branches     = "dynamic"                                    # Conventional commits apply to all branches
  }
}

# ============================================================================
# INFRASTRUCTURE OUTPUTS
# ============================================================================

output "runner_groups" {
  description = "GitHub Actions runner groups configuration"
  value = {
    total = length(module.github_org.runner_group_ids)
    groups = {
      production = try(module.github_org.runner_group_ids["production-runners"], null)
      general    = try(module.github_org.runner_group_ids["general-runners"], null)
    }
  }
}

output "environments_summary" {
  description = "Deployment environments across repositories"
  value = {
    repositories_with_environments = length([
      for k, r in module.github_org.repositories :
      k if length(try(r.environments, {})) > 0
    ])
    total_environments = sum([
      for k, r in module.github_org.repositories :
      length(try(r.environments, {}))
    ])
  }
}

# ============================================================================
# PERFORMANCE METRICS
# ============================================================================

output "configuration_complexity" {
  description = "Metrics about configuration size and complexity"
  value = {
    repositories          = module.github_org.repositories_summary.total
    organization_rulesets = length(module.github_org.ruleset_ids)
    runner_groups         = length(module.github_org.runner_group_ids)

    # Estimate of total resources managed
    estimated_branches_protected = module.github_org.repositories_summary.total * 2 # main + develop avg
    estimated_environments       = sum([for k, r in module.github_org.repositories : length(try(r.environments, {}))])
    estimated_team_memberships   = module.github_org.repositories_summary.total * 2 # avg 2 teams per repo
  }
}

output "dry_efficiency" {
  description = "DRY efficiency metrics (settings reuse)"
  value = {
    repositories_using_defaults = module.github_org.repositories_summary.total
    settings_inherited          = "100%" # All repos inherit from settings
    unique_configurations = length([
      for k, r in module.github_org.repositories :
      k if length(try(r.environments, {})) > 0 || length(try(r.teams, {})) > 0
    ])
  }
}

# ============================================================================
# TEAM ACCESS OUTPUTS
# ============================================================================

output "team_repository_access" {
  description = "Summary of team access across repositories"
  value = {
    total_team_grants = sum([
      for k, r in module.github_org.repositories :
      length(try(r.teams, {}))
    ])

    # Estimated unique teams from settings
    organization_teams = [
      "platform-team",
      "security-team",
      "developers",
      "contractors",
      "frontend-team",
      "sre-team",
      "data-team",
      "analytics-team",
      "mobile-team",
      "qa-team",
      "documentation-team",
      "opensource-team"
    ]
  }
}
