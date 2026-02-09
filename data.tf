# Pre-fetch team and app IDs to avoid repeated API calls during repository creation

# Conditional fetch: only if corresponding var.github_*_ids is empty
data "github_organization_teams" "all" {
  count           = length(var.github_team_ids) == 0 ? 1 : 0
  root_teams_only = false
  summary_only    = false
}

# Fetch user data for referenced users (only if not provided)
data "github_user" "referenced_users" {
  for_each = length(var.github_user_ids) == 0 ? toset(local.all_user_logins) : toset([])
  username = each.value
}

# Fetch organization custom roles (only if custom roles are detected)
data "github_organization_repository_roles" "all" {
  count = local.has_custom_roles ? 1 : 0
}

# Fetch app installation data for referenced apps (only if not provided)
data "github_app" "bypass_apps" {
  for_each = length(var.github_app_ids) == 0 ? toset(local.bypass_app_slugs) : toset([])
  slug     = each.value
}
