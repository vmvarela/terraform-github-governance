# Pre-fetch team and app IDs to avoid repeated API calls during repository creation

# Conditional fetch: only if corresponding var.github_*_ids is empty
data "github_organization_teams" "all" {
  count           = length(var.github_team_ids) == 0 ? 1 : 0
  root_teams_only = false
  summary_only    = false
}

# Extract unique app slugs from allow_bypass for selective fetch
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

  # Note: User IDs must be provided manually or resolved individually by repository module
  # Cannot fetch from data.github_organization.members as it returns node IDs (strings), not numeric IDs
  github_user_ids = var.github_user_ids

  github_app_ids = length(var.github_app_ids) > 0 ? var.github_app_ids : {
    for slug, app in data.github_app.bypass_apps : slug => app.id
  }
}
