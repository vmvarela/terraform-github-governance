# Pre-fetch team and app IDs to avoid repeated API calls during repository creation

# Conditional fetch: only if corresponding var.github_*_ids is empty
data "github_organization_teams" "all" {
  count           = length(var.github_team_ids) == 0 ? 1 : 0
  root_teams_only = false
  summary_only    = false
}

# Extract unique app slugs and user logins from repositories for selective fetch
locals {
  all_bypass_entries = flatten([
    for k, repo in var.repositories : concat(
      coalesce(try(var.presets[repo.preset].allow_bypass, []), []),
      coalesce(try(repo.allow_bypass, []), [])
    )
  ])

  bypass_app_slugs = distinct([
    for entry in local.all_bypass_entries : trimprefix(entry, "app:")
    if startswith(entry, "app:")
  ])

  # Extract user logins from permissions and environment reviewers
  all_user_logins = distinct(flatten([
    for k, repo in var.repositories : concat(
      # From permissions
      [
        for perm_key in keys(coalesce(repo.permissions, {})) : split(":", perm_key)[1]
        if startswith(perm_key, "user:")
      ],
      # From environment required_approvers
      flatten([
        for env in values(coalesce(repo.environments, {})) : [
          for approver in coalesce(env.required_approvers, []) : split(":", approver)[1]
          if startswith(approver, "user:")
        ]
      ])
    )
  ]))
}

# Fetch user data for referenced users (only if not provided)
data "github_user" "referenced_users" {
  for_each = length(var.github_user_ids) == 0 ? toset(local.all_user_logins) : []
  username = each.value
}

# Fetch app installation data for referenced apps (only if not provided)
data "github_app" "bypass_apps" {
  for_each = length(var.github_app_ids) == 0 ? toset(local.bypass_app_slugs) : []
  slug     = each.value
}

# Build maps of slug/login -> ID for passing to repository module
locals {
  github_team_ids = length(var.github_team_ids) > 0 ? var.github_team_ids : {
    for team in data.github_organization_teams.all[0].teams :
    team.slug => team.id
  }

  # Build user ID map from individual user data sources
  github_user_ids = length(var.github_user_ids) > 0 ? var.github_user_ids : {
    for login, user in data.github_user.referenced_users :
    login => user.id
  }

  github_app_ids = length(var.github_app_ids) > 0 ? var.github_app_ids : {
    for slug, app in data.github_app.bypass_apps : slug => app.id
  }
}
