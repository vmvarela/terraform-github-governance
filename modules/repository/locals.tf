# Local values for repository submodule

locals {
  # Team slugs from allow_bypass actors
  bypass_team_slugs = [
    for actor in var.allow_bypass : split(":", actor)[1]
    if startswith(actor, "team:")
  ]

  # Team slugs from environment required_approvers
  env_team_slugs = flatten([
    for env in values(var.environments != null ? var.environments : {}) : [
      for a in lookup(env, "required_approvers", []) : split(":", a)[1]
      if startswith(a, "team:")
    ]
  ])

  # User logins from environment required_approvers
  env_user_logins = flatten([
    for env in values(var.environments != null ? var.environments : {}) : [
      for a in lookup(env, "required_approvers", []) : split(":", a)[1]
      if startswith(a, "user:")
    ]
  ])

  # Build sorted list of bypass actors with resolved IDs for consistent ordering
  bypass_actors_with_ids = [
    for actor in var.allow_bypass : {
      original = actor
      actor_id = (
        actor == "org-admin" ? 1 :
        actor == "role:maintain" ? 2 :
        actor == "role:write" ? 4 :
        actor == "role:admin" ? 5 :
        startswith(actor, "team:") ? var.github_team_ids[split(":", actor)[1]] :
        startswith(actor, "app:") ? var.github_app_ids[split(":", actor)[1]] :
        0
      )
      actor_type = (
        actor == "org-admin" ? "OrganizationAdmin" :
        startswith(actor, "role:") ? "RepositoryRole" :
        startswith(actor, "team:") ? "Team" :
        startswith(actor, "app:") ? "Integration" :
        ""
      )
    }
  ]

  # Sort by actor_id to ensure consistent ordering and prevent unnecessary updates
  bypass_actors_sorted = sort([
    for actor in local.bypass_actors_with_ids :
    format("%010d-%s", actor.actor_id, actor.actor_type)
  ])

  bypass_actors_final = [
    for key in local.bypass_actors_sorted :
    [
      for actor in local.bypass_actors_with_ids :
      actor if format("%010d-%s", actor.actor_id, actor.actor_type) == key
    ][0]
  ]

  # Environment reviewers (teams/users) declared across environments
  env_reviewers = distinct(flatten([
    for env in values(var.environments != null ? var.environments : {}) :
    lookup(env, "required_approvers", [])
  ]))

  # Current permissions map (may be null)
  user_permissions = var.permissions != null ? var.permissions : {}

  # Roles meeting minimum requirement to review environments
  min_push_roles = ["push", "maintain", "admin"]

  # Reviewers missing minimum permissions (not present OR present with lower than push)
  reviewers_needing_push = {
    for r in local.env_reviewers :
    r => "push"
    if !contains(local.min_push_roles, lookup(local.user_permissions, r, ""))
  }

  # Final permissions: start from user-defined and upgrade reviewers to at least push
  final_permissions = merge(
    local.user_permissions,
    local.reviewers_needing_push
  )
}
