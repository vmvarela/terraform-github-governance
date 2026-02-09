# Local values for governance module

locals {
  # Default preset values used to fill any missing attributes from var.presets
  preset_base_default = {
    visibility              = "private"
    default_branch          = "main"
    topics                  = []
    properties              = {}
    protected_branches      = ["main"]
    allow_bypass            = []
    required_approvals      = 1
    required_checks         = []
    prevent_force_push      = true
    prevent_branch_deletion = true

    # Merge settings
    allow_merge_commit          = true
    allow_squash_merge          = true
    allow_rebase_merge          = true
    allow_auto_merge            = false
    delete_branch_on_merge      = false
    allow_update_branch         = false
    squash_merge_commit_title   = null
    squash_merge_commit_message = null
    merge_commit_title          = null
    merge_commit_message        = null

    # Feature toggles
    has_issues      = true
    has_wiki        = true
    has_projects    = true
    has_discussions = false

    # Security
    vulnerability_alerts        = true
    web_commit_signoff_required = false
  }

  # Resolve the effective preset for each repository once
  resolved_presets = {
    for key, repo in var.repositories : key => merge(
      local.preset_base_default,
      try(var.presets[repo.preset], var.presets["default"], {})
    )
  }

  # Process each repository: merge resolved preset with per-repo overrides
  processed_repositories = {
    for key, repo in var.repositories : key => {
      # Final repository name (always apply repository_naming format)
      name = format(var.repository_naming, coalesce(repo.name, key))

      # Merge properties: preset properties + workspace + repo overrides
      properties = merge(
        try(local.preset_base_default.properties, {}),
        try(local.resolved_presets[key].properties, {}),
        { workspace = var.workspace },
        try(repo.properties, {})
      )

      # Core configuration (repo overrides preset)
      description    = trimspace(join("", compact([try(repo.description, null), try(local.resolved_presets[key].description, null)])))
      visibility     = coalesce(try(repo.visibility, null), try(local.resolved_presets[key].visibility, null), local.preset_base_default.visibility)
      default_branch = coalesce(try(repo.default_branch, null), try(local.resolved_presets[key].default_branch, null), local.preset_base_default.default_branch)
      topics         = coalesce(try(repo.topics, null), try(local.resolved_presets[key].topics, null), local.preset_base_default.topics)

      # Template configuration (pass through)
      is_template = try(repo.is_template, null)
      template    = try(repo.template, null)

      # Access & Permissions (pass through)
      permissions   = try(repo.permissions, {})
      deploy_keys   = try(repo.deploy_keys, {})
      allowed_roles = try(repo.allowed_roles, null)

      # Automation (pass through)
      webhooks             = try(repo.webhooks, {})
      repository_secrets   = try(repo.repository_secrets, {})
      repository_variables = try(repo.repository_variables, {})

      # CI/CD Environments (pass through)
      environments = try(repo.environments, {})

      # Flattened Branch Protection: merge preset + repo overrides
      protected_branches      = coalesce(try(repo.protected_branches, null), try(local.resolved_presets[key].protected_branches, null), local.preset_base_default.protected_branches)
      allow_bypass            = coalesce(try(repo.allow_bypass, null), try(local.resolved_presets[key].allow_bypass, null), local.preset_base_default.allow_bypass)
      required_approvals      = coalesce(try(repo.required_approvals, null), try(local.resolved_presets[key].required_approvals, null), local.preset_base_default.required_approvals)
      required_checks         = coalesce(try(repo.required_checks, null), try(local.resolved_presets[key].required_checks, null), local.preset_base_default.required_checks)
      prevent_force_push      = coalesce(try(repo.prevent_force_push, null), try(local.resolved_presets[key].prevent_force_push, null), local.preset_base_default.prevent_force_push)
      prevent_branch_deletion = coalesce(try(repo.prevent_branch_deletion, null), try(local.resolved_presets[key].prevent_branch_deletion, null), local.preset_base_default.prevent_branch_deletion)

      # Merge settings: merge preset + repo overrides
      allow_merge_commit          = coalesce(try(repo.allow_merge_commit, null), try(local.resolved_presets[key].allow_merge_commit, null), local.preset_base_default.allow_merge_commit)
      allow_squash_merge          = coalesce(try(repo.allow_squash_merge, null), try(local.resolved_presets[key].allow_squash_merge, null), local.preset_base_default.allow_squash_merge)
      allow_rebase_merge          = coalesce(try(repo.allow_rebase_merge, null), try(local.resolved_presets[key].allow_rebase_merge, null), local.preset_base_default.allow_rebase_merge)
      allow_auto_merge            = coalesce(try(repo.allow_auto_merge, null), try(local.resolved_presets[key].allow_auto_merge, null), local.preset_base_default.allow_auto_merge)
      delete_branch_on_merge      = coalesce(try(repo.delete_branch_on_merge, null), try(local.resolved_presets[key].delete_branch_on_merge, null), local.preset_base_default.delete_branch_on_merge)
      allow_update_branch         = coalesce(try(repo.allow_update_branch, null), try(local.resolved_presets[key].allow_update_branch, null), local.preset_base_default.allow_update_branch)
      squash_merge_commit_title   = try(repo.squash_merge_commit_title, null) != null ? repo.squash_merge_commit_title : try(local.resolved_presets[key].squash_merge_commit_title, null)
      squash_merge_commit_message = try(repo.squash_merge_commit_message, null) != null ? repo.squash_merge_commit_message : try(local.resolved_presets[key].squash_merge_commit_message, null)
      merge_commit_title          = try(repo.merge_commit_title, null) != null ? repo.merge_commit_title : try(local.resolved_presets[key].merge_commit_title, null)
      merge_commit_message        = try(repo.merge_commit_message, null) != null ? repo.merge_commit_message : try(local.resolved_presets[key].merge_commit_message, null)

      # Feature toggles: merge preset + repo overrides
      has_issues      = coalesce(try(repo.has_issues, null), try(local.resolved_presets[key].has_issues, null), local.preset_base_default.has_issues)
      has_wiki        = coalesce(try(repo.has_wiki, null), try(local.resolved_presets[key].has_wiki, null), local.preset_base_default.has_wiki)
      has_projects    = coalesce(try(repo.has_projects, null), try(local.resolved_presets[key].has_projects, null), local.preset_base_default.has_projects)
      has_discussions = coalesce(try(repo.has_discussions, null), try(local.resolved_presets[key].has_discussions, null), local.preset_base_default.has_discussions)

      # Repository-only settings (not inherited from presets)
      archived     = coalesce(try(repo.archived, null), false)
      homepage_url = try(repo.homepage_url, null)

      # Security: merge preset + repo overrides
      vulnerability_alerts        = coalesce(try(repo.vulnerability_alerts, null), try(local.resolved_presets[key].vulnerability_alerts, null), local.preset_base_default.vulnerability_alerts)
      web_commit_signoff_required = coalesce(try(repo.web_commit_signoff_required, null), try(local.resolved_presets[key].web_commit_signoff_required, null), local.preset_base_default.web_commit_signoff_required)

      # Store the preset name for reference
      preset_name = repo.preset
    }
  }
}

# Pre-fetched ID resolution locals (from data sources)
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
      [
        for perm_key in keys(coalesce(repo.permissions, {})) : split(":", perm_key)[1]
        if startswith(perm_key, "user:")
      ],
      flatten([
        for env in values(coalesce(repo.environments, {})) : [
          for approver in coalesce(env.required_approvers, []) : split(":", approver)[1]
          if startswith(approver, "user:")
        ]
      ])
    )
  ]))

  # Extract all roles used in permissions across all repositories
  base_roles = ["pull", "triage", "push", "maintain", "admin"]
  all_permission_roles = distinct(flatten([
    for k, repo in var.repositories :
    values(coalesce(repo.permissions, {}))
  ]))

  # Check if any role is not in base_roles
  has_custom_roles = length([
    for role in local.all_permission_roles :
    role if !contains(local.base_roles, role)
  ]) > 0
}

# Build maps of slug/login -> ID for passing to repository module
locals {
  github_team_ids = length(var.github_team_ids) > 0 ? var.github_team_ids : {
    for team in data.github_organization_teams.all[0].teams :
    team.slug => team.id
  }

  github_user_ids = length(var.github_user_ids) > 0 ? var.github_user_ids : {
    for login, user in data.github_user.referenced_users :
    login => user.id
  }

  github_app_ids = length(var.github_app_ids) > 0 ? var.github_app_ids : {
    for slug, app in data.github_app.bypass_apps : slug => app.id
  }

  # Build allowed roles list: base roles + custom roles (if fetched)
  allowed_roles = local.has_custom_roles ? concat(
    local.base_roles,
    [for role in data.github_organization_repository_roles.all[0].roles : role.name]
  ) : local.base_roles
}
