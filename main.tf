locals {

  # empty settings is a map with all possible keys set to null
  empty_settings = {
    for key in concat(local.coalesce_keys, local.merge_keys, local.union_keys) : key => null
  }

  # you can set var.users and var.teams or var.settings.users and var.settings.teams
  settings = merge(local.empty_settings, var.settings, {
    "users" = merge(var.users, try(var.settings.users, {}))
    "teams" = merge(var.teams, try(var.settings.teams, {}))
  })

  defaults = merge(local.empty_settings, var.defaults)

  # keys to set if empty: (1) settings, (2) repository, (3) defaults
  coalesce_keys = [
    "actions_access_level",
    "actions_allowed_github",
    "actions_allowed_patterns",
    "actions_allowed_policy",
    "actions_allowed_verified",
    "workflow_permissions",
    "allow_auto_merge",
    "allow_merge_commit",
    "allow_rebase_merge",
    "allow_squash_merge",
    "allow_update_branch",
    "archive_on_destroy",
    "archived",
    "auto_init",
    "default_branch",
    "delete_branch_on_merge",
    "dependabot_copy_secrets",
    "deploy_keys_path",
    "enable_actions",
    "enable_advanced_security",
    "enable_dependency_graph",
    "enable_dependabot_security_updates",
    "enable_secret_scanning",
    "enable_secret_scanning_push_protection",
    "enable_vulnerability_alerts",
    "gitignore_template",
    "has_downloads",
    "has_issues",
    "has_projects",
    "has_wiki",
    "homepage",
    "is_template",
    "license_template",
    "merge_commit_message",
    "merge_commit_title",
    "pages_build_type",
    "pages_cname",
    "pages_source_branch",
    "pages_source_path",
    "private",
    "squash_merge_commit_message",
    "squash_merge_commit_title",
    "template",
    "template_include_all_branches",
    "visibility",
    "web_commit_signoff_required"
  ]

  # keys to merge (settings + repository), defaults if empty
  merge_keys = [
    "autolink_references",
    "branches",
    "custom_properties",
    "custom_properties_types",
    "dependabot_secrets",
    "dependabot_secrets_encrypted",
    "deploy_keys",
    "environments",
    "issue_labels",
    "issue_labels_colors",
    "rulesets",
    "secrets",
    "secrets_encrypted",
    "teams",
    "users",
    "variables",
    "webhooks"
  ]

  # keys to add (settings + repository), defaults if empty
  union_keys = [
    "files",
    "topics"
  ]

  # format spec for repository name
  spec = var.mode == "organization" ? "%s" : (var.spec != null ? replace(var.spec, "/[^a-zA-Z0-9-%]/", "") : "%s")

  # ========================================================================
  # REPOSITORY CONFIGURATION MERGE LOGIC (Refactored for readability)
  # ========================================================================

  # Step 1: Build base configuration per repository from coalesce_keys
  # Priority: settings > repository > defaults (policy enforcement)
  repos_base_config = { for repo, data in var.repositories :
    repo => {
      for k in local.coalesce_keys :
      k => try(
        coalesce(
          lookup(local.settings, k, null),
          lookup(data, k, null),
          lookup(var.defaults, k, null)
        ),
        null
      )
    }
  }

  # Step 2: Build merge configuration per repository from merge_keys
  # Priority: settings > repository > defaults (settings wins on key conflicts)
  repos_merge_config = { for repo, data in var.repositories :
    repo => {
      for k in local.merge_keys :
      k => (
        length(merge(
          try(data[k], null) != null ? (can(data[k]) ? try(data[k], {}) : {}) : {},
          try(local.settings[k], null) != null ? (can(local.settings[k]) ? try(local.settings[k], {}) : {}) : {}
        )) > 0
        ? merge(
          try(data[k], null) != null ? (can(data[k]) ? try(data[k], {}) : {}) : {},
          try(local.settings[k], null) != null ? (can(local.settings[k]) ? try(local.settings[k], {}) : {}) : {}
        )
        : try(var.defaults[k], {})
      )
    }
  }

  # Step 3: Build union configuration per repository from union_keys
  # Combines: repository + settings (union of both sets/lists)
  # For 'files': uses concat (list of objects)
  # For 'topics': uses setunion (set of strings)
  repos_union_config = { for repo, data in var.repositories :
    repo => {
      for k in local.union_keys :
      k => (
        k == "files" ? (
          length(concat(
            try(data[k], null) != null && can(tolist(data[k])) ? tolist(data[k]) : [],
            try(local.settings[k], null) != null && can(tolist(local.settings[k])) ? tolist(local.settings[k]) : []
          )) > 0
          ? concat(
            try(data[k], null) != null && can(tolist(data[k])) ? tolist(data[k]) : [],
            try(local.settings[k], null) != null && can(tolist(local.settings[k])) ? tolist(local.settings[k]) : []
          )
          : try(var.defaults[k], null) != null && can(tolist(var.defaults[k])) ? tolist(var.defaults[k]) : []
          ) : tolist(
          length(setunion(
            [],
            try(data[k], null) != null && can(tolist(data[k])) ? tolist(data[k]) : [],
            try(local.settings[k], null) != null && can(tolist(local.settings[k])) ? tolist(local.settings[k]) : []
          )) > 0
          ? setunion(
            try(data[k], null) != null && can(tolist(data[k])) ? tolist(data[k]) : [],
            try(local.settings[k], null) != null && can(tolist(local.settings[k])) ? tolist(local.settings[k]) : []
          )
          : try(var.defaults[k], null) != null && can(tolist(var.defaults[k])) ? tolist(var.defaults[k]) : []
        )
      )
    }
  }

  # Step 4: Final assembly - Combine all configurations
  # Use repository alias if provided, otherwise use key
  repositories = { for repo, data in var.repositories :
    repo => merge(
      # Description (separate as it's always repository-specific)
      { alias = try(data.alias, null), description = try(data.description, null) },

      # Base configuration (coalesced)
      local.repos_base_config[repo],

      # Merge configuration (merged maps)
      local.repos_merge_config[repo],

      # Union configuration (union of lists)
      local.repos_union_config[repo]
    )
  }

  # ========================================================================
  # END REPOSITORY CONFIGURATION MERGE LOGIC
  # ========================================================================

  # ========================================================================
  # APPLY GLOBAL USER OPTIMIZATION TO REPOSITORIES
  # ========================================================================
  # APPLY GLOBAL USER OPTIMIZATION TO REPOSITORIES (Project Mode Only)
  # ========================================================================
  # In project mode: Replace optimized global users with team assignments
  # In organization mode: Keep as-is (organization roles handle permissions globally)

  # Build map of optimized team IDs by role (for reference after team creation)
  optimized_team_ids = local.is_project_mode ? {
    for role in keys(local.optimizable_global_roles) :
    role => github_team.global_role_teams[role].id
  } : {}

  repositories_optimized = local.is_project_mode ? {
    for repo_key, repo_config in local.repositories :
    repo_key => merge(repo_config, {
      # Remove global users that are now in optimized teams
      users = {
        for user, role in try(repo_config.users, {}) :
        user => role
        # Keep user if: NOT a global user OR role is not optimizable
        if !(contains(keys(local.settings.users), user) && contains(keys(local.optimizable_global_roles), role))
      }
      # Add optimized teams with their role permissions
      teams = merge(
        try(repo_config.teams, {}),
        # Add team ID => role mapping for optimized teams
        {
          for role in keys(local.optimizable_global_roles) :
          local.optimized_team_ids[role] => role
        }
      )
    })
  } : local.repositories # In organization mode, no changes needed

  github_org        = var.mode == "organization" ? var.name : var.github_org
  info_repositories = var.info_repositories != null ? var.info_repositories : try(data.github_repositories.all[0], null)

  # Map of repository name to ID from existing repositories in the organization
  github_repository_id_external = { for r in try(local.info_repositories.names, []) :
    r => element(local.info_repositories.repo_ids, index(local.info_repositories.names, r))
  }

  # Map of repository name to ID from repositories managed by this module
  github_repository_id_managed = { for name, repo in github_repository.repo :
    repo.name => repo.repo_id
  }

  # Combined map: managed repos take precedence over external repos
  github_repository_id = merge(
    local.github_repository_id_external,
    local.github_repository_id_managed
  )

  info_organization = var.info_organization != null ? var.info_organization : try(data.github_organization.this[0], null)
  github_plan       = lower(local.info_organization.plan)

  # DRY: Mode-related computed values
  is_project_mode        = var.mode == "project"
  project_repository_ids = local.is_project_mode ? [for k, r in github_repository.repo : r.repo_id] : []

  # ========================================================================
  # GLOBAL USER ROLE OPTIMIZATION
  # Groups global users (var.users) by role to create teams/roles when 2+ users share the same role
  # Only affects users defined at module level, NOT repository-specific users
  # ========================================================================

  # Step 1: Group global users by role
  # Source: var.users (merged into local.settings.users)
  # Result: { "admin" => ["user1", "user2"], "write" => ["user3", "user4"] }
  global_users_by_role = {
    for role in distinct(values(local.settings.users)) :
    role => [for user, user_role in local.settings.users : user if user_role == role]
  }

  # Step 2: Identify roles with 2+ users (eligible for team/role optimization)
  # Result: { "admin" => ["user1", "user2"] } (only roles with 2+ users)
  optimizable_global_roles = {
    for role, users in local.global_users_by_role :
    role => users
    if length(users) >= 2
  }

  # Step 3: Generate team/role names
  # Organization mode: role name = "auto-<role>" (will create organization_role)
  # Project mode: team name = "<project-name>-<role>" (will create github_team)
  optimized_role_names = {
    for role in keys(local.optimizable_global_roles) :
    role => local.is_project_mode ? "${var.name}-${role}" : "auto-${role}"
  }
}

# ========================================================================
# DATA SOURCES
# ========================================================================

data "github_repositories" "all" {
  count           = var.info_repositories == null ? 1 : 0
  query           = "org:${local.github_org}"
  include_repo_id = true
}

# Fetch organization information to check plan type
data "github_organization" "this" {
  count = var.info_organization == null ? 1 : 0
  name  = local.github_org
}

# ========================================================================
# VALIDATION CHECKS
# ========================================================================

# Validate organization plan for features that require paid plans
check "organization_plan_validation" {
  assert {
    condition = try(length(var.webhooks), 0) == 0 || local.github_plan != "free"

    error_message = <<-EOT
      [TF-GH-001] ❌ Organization webhooks require GitHub Team, Business, or Enterprise plan.
      Current plan: ${local.github_plan}

      Solutions:
        1. Remove the 'webhooks' configuration from your module
        2. Use repository-level webhooks instead (configure in each repository)
        3. Upgrade your organization plan at: https://github.com/organizations/${local.github_org}/settings/billing

      Error occurs at: github_organization_webhook resource
      Documentation: https://docs.github.com/en/organizations/managing-organization-settings/about-webhooks
    EOT
  }

  assert {
    condition = try(length(var.rulesets), 0) == 0 || local.github_plan != "free"

    error_message = <<-EOT
      [TF-GH-002] ❌ Organization rulesets require GitHub Team, Business, or Enterprise plan.
      Current plan: ${local.github_plan}

      Solutions:
        1. Remove the 'rulesets' configuration from your module
        2. Use repository-level branch protection rules instead
        3. Upgrade your organization plan at: https://github.com/organizations/${local.github_org}/settings/billing

      Error occurs at: github_organization_ruleset resource
      Documentation: https://docs.github.com/en/organizations/managing-organization-settings/managing-rulesets-for-repositories-in-your-organization
    EOT
  }

  assert {
    condition = try(length(var.repository_roles), 0) == 0 || contains(["enterprise", "enterprise_cloud"], local.github_plan)

    error_message = <<-EOT
      [TF-GH-003] ❌ Custom repository roles require GitHub Enterprise plan.
      Current plan: ${local.github_plan}

      Solutions:
        1. Remove the 'repository_roles' configuration from your module
        2. Use standard roles (read, triage, write, maintain, admin) instead
        3. Upgrade to GitHub Enterprise at: https://github.com/organizations/${local.github_org}/settings/billing

      Error occurs at: github_organization_repository_role resource
      Documentation: https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-peoples-access-to-your-organization-with-roles/managing-custom-repository-roles-for-an-organization
    EOT
  }
}

# Validate that internal repositories are only used with appropriate plans
check "internal_repositories_validation" {
  assert {
    condition = alltrue([
      for name, repo in var.repositories :
      try(repo.visibility, "private") != "internal" || contains(["business", "enterprise", "enterprise_cloud"], local.github_plan)
    ])

    error_message = <<-EOT
      [TF-GH-004] ❌ Internal repositories require GitHub Business or Enterprise plan.
      Current plan: ${local.github_plan}

      Repositories with 'internal' visibility: ${join(", ", [
    for name, repo in var.repositories : name if try(repo.visibility, "") == "internal"
])}

      Solutions:
        1. Change visibility to 'private' or 'public' for these repositories
        2. Upgrade to Business or Enterprise plan at: https://github.com/organizations/${local.github_org}/settings/billing

      Documentation: https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories#about-internal-repositories
    EOT
}
}

# Warn about runner_groups visibility configuration
check "runner_groups_validation" {
  assert {
    condition = local.is_project_mode || alltrue([
      for name, rg in var.runner_groups :
      try(rg.visibility, "all") != "selected" || length(try(rg.repositories, [])) > 0
    ])

    error_message = <<-EOT
      [TF-GH-005] ❌ Runner groups with visibility='selected' must have at least one repository specified.

      Runner groups with empty repositories list: ${join(", ", [
    for name, rg in var.runner_groups : name
    if try(rg.visibility, "all") == "selected" && length(try(rg.repositories, [])) == 0
])}

      Solution: Add repositories to the runner group or change visibility to 'all' or 'private'

      Note: In project mode, runner groups automatically use all managed repositories.
      Documentation: https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/managing-access-to-self-hosted-runners-using-groups
    EOT
}

assert {
  condition = var.mode != "project" || alltrue([
    for name, rg in var.runner_groups :
    length(try(rg.repositories, [])) == 0
  ])

  error_message = <<-EOT
      ❌ In project mode, runner groups cannot specify custom repositories.

      Runner groups with 'repositories' configured: ${join(", ", [
  for name, rg in var.runner_groups : name
  if length(try(rg.repositories, [])) > 0
])}

      Reason: Project mode restricts runner groups to only the repositories managed by this module.

      Solution: Remove the 'repositories' field from runner groups. They will automatically use all project repositories.
    EOT
}
}

# ========================================================================
# ORGANIZATION-WIDE VARIABLES AND SECRETS
# ========================================================================

# actions_organization_variable
resource "github_actions_organization_variable" "this" {
  for_each                = var.variables != null ? var.variables : {}
  variable_name           = upper(replace(format(local.spec, each.key), "-", "_"))
  value                   = each.value
  visibility              = local.is_project_mode ? "selected" : "all"
  selected_repository_ids = local.is_project_mode ? local.project_repository_ids : null
}

# actions_organization_secrets (plaintext)
resource "github_actions_organization_secret" "plaintext" {
  for_each                = var.secrets != null ? var.secrets : {}
  secret_name             = upper(replace(format(local.spec, each.key), "-", "_"))
  plaintext_value         = each.value
  visibility              = local.is_project_mode ? "selected" : "all"
  selected_repository_ids = local.is_project_mode ? local.project_repository_ids : null
}

# actions_organization_secrets (encrypted)
resource "github_actions_organization_secret" "encrypted" {
  for_each                = var.secrets_encrypted != null ? var.secrets_encrypted : {}
  secret_name             = upper(replace(format(local.spec, each.key), "-", "_"))
  encrypted_value         = each.value
  visibility              = local.is_project_mode ? "selected" : "all"
  selected_repository_ids = local.is_project_mode ? local.project_repository_ids : null
}

# dependabot_organization_secret (plaintext)
resource "github_dependabot_organization_secret" "plaintext" {
  for_each                = coalesce(var.dependabot_secrets, (var.dependabot_copy_secrets ? var.secrets : {}), {})
  secret_name             = upper(replace(format(local.spec, each.key), "-", "_"))
  plaintext_value         = each.value
  visibility              = local.is_project_mode ? "selected" : "all"
  selected_repository_ids = local.is_project_mode ? local.project_repository_ids : null
}

# dependabot_organization_secret (encrypted)
resource "github_dependabot_organization_secret" "encrypted" {
  for_each                = var.dependabot_secrets_encrypted != null ? var.dependabot_secrets_encrypted : {}
  secret_name             = upper(replace(format(local.spec, each.key), "-", "_"))
  encrypted_value         = each.value
  visibility              = local.is_project_mode ? "selected" : "all"
  selected_repository_ids = local.is_project_mode ? local.project_repository_ids : null
}

# ========================================================================
# RUNNER GROUPS
# ========================================================================

# actions_runner_group
resource "github_actions_runner_group" "this" {
  for_each = var.runner_groups
  name     = format(local.spec, each.key)

  # In project mode: always 'selected' with module repositories only
  # In organization mode: use configured visibility (all/selected/private)
  visibility = local.is_project_mode ? "selected" : try(each.value.visibility, "all")

  # Convert repository names to IDs for selected_repository_ids
  selected_repository_ids = (
    local.is_project_mode ?
    # PROJECT MODE: Only allow repositories managed by this module
    # Ignore any 'repositories' config - use all module repos
    local.project_repository_ids :

    # ORGANIZATION MODE: Allow any repository in the organization
    try(each.value.visibility, "all") == "selected" && length(try(each.value.repositories, [])) > 0 ?
    # Filter out nulls from failed lookups (repo doesn't exist)
    compact([for repo_ref in each.value.repositories :
      # Support both numeric IDs and repository names
      can(tonumber(repo_ref)) ?
      tonumber(repo_ref) :
      lookup(local.github_repository_id, repo_ref, null)
    ]) :
    null
  )

  restricted_to_workflows = try(each.value.workflows, null) != null
  selected_workflows      = try(each.value.workflows, null)

  lifecycle {
    # PROTECTION: Runner groups contain infrastructure configuration
    prevent_destroy = true

    # STRATEGY: Allow modifications without recreating
    create_before_destroy = true
  }

  # Ensure repositories are resolved before creating runner group
  depends_on = [github_repository.repo]
}

# ========================================================================
# ORGANIZATION RULESETS (Dual-Mode: Organization + Project)
# ========================================================================

# organization_ruleset
# NOTE: Works in BOTH organization and project modes
# - Organization mode: Applies to all repos in organization (using var.spec for naming)
# - Project mode: Applies only to repos managed by this module
resource "github_organization_ruleset" "this" {
  for_each    = coalesce(var.rulesets, {})
  name        = format(local.spec, each.key)
  enforcement = each.value.enforcement

  lifecycle {
    # PROTECTION: Critical rulesets should not be destroyed without review
    prevent_destroy = true

    # STRATEGY: Allow modifications without recreating the resource
    create_before_destroy = true
  }

  rules {
    dynamic "branch_name_pattern" {
      for_each = try(each.value.rules.branch_name_pattern, null) != null ? [1] : []
      content {
        operator = each.value.rules.branch_name_pattern.operator
        pattern  = each.value.rules.branch_name_pattern.pattern
        name     = each.value.rules.branch_name_pattern.name
        negate   = each.value.rules.branch_name_pattern.negate
      }
    }
    dynamic "commit_author_email_pattern" {
      for_each = try(each.value.rules.commit_author_email_pattern, null) != null ? [1] : []
      content {
        operator = each.value.rules.commit_author_email_pattern.operator
        pattern  = each.value.rules.commit_author_email_pattern.pattern
        name     = each.value.rules.commit_author_email_pattern.name
        negate   = each.value.rules.commit_author_email_pattern.negate
      }
    }
    dynamic "commit_message_pattern" {
      for_each = try(each.value.rules.commit_message_pattern, null) != null ? [1] : []
      content {
        operator = each.value.rules.commit_message_pattern.operator
        pattern  = each.value.rules.commit_message_pattern.pattern
        name     = each.value.rules.commit_message_pattern.name
        negate   = each.value.rules.commit_message_pattern.negate
      }
    }
    dynamic "committer_email_pattern" {
      for_each = try(each.value.rules.committer_email_pattern, null) != null ? [1] : []
      content {
        operator = each.value.rules.committer_email_pattern.operator
        pattern  = each.value.rules.committer_email_pattern.pattern
        name     = each.value.rules.committer_email_pattern.name
        negate   = each.value.rules.committer_email_pattern.negate
      }
    }
    creation         = try(each.value.rules.creation, null)
    deletion         = try(each.value.rules.deletion, null)
    non_fast_forward = try(each.value.rules.non_fast_forward, null)
    dynamic "pull_request" {
      for_each = try(each.value.rules.pull_request, null) != null ? [1] : []
      content {
        dismiss_stale_reviews_on_push     = each.value.rules.pull_request.dismiss_stale_reviews_on_push
        require_code_owner_review         = each.value.rules.pull_request.require_code_owner_review
        require_last_push_approval        = each.value.rules.pull_request.require_last_push_approval
        required_approving_review_count   = each.value.rules.pull_request.required_approving_review_count
        required_review_thread_resolution = each.value.rules.pull_request.required_review_thread_resolution
      }
    }
    required_linear_history = try(each.value.rules.required_linear_history, null)
    required_signatures     = try(each.value.rules.required_signatures, null)
    dynamic "required_status_checks" {
      for_each = (try(each.value.rules.required_status_checks, null) != null) ? [1] : []
      content {
        dynamic "required_check" {
          for_each = each.value.rules.required_status_checks
          content {
            context        = required_check.key
            integration_id = required_check.value
          }
        }
        strict_required_status_checks_policy = each.value.strict_required_status_checks_policy
      }
    }
    dynamic "tag_name_pattern" {
      for_each = try(each.value.rules.tag_name_pattern, null) != null ? [1] : []
      content {
        operator = each.value.rules.tag_name_pattern.operator
        pattern  = each.value.rules.tag_name_pattern.pattern
        name     = each.value.rules.tag_name_pattern.name
        negate   = each.value.rules.tag_name_pattern.negate
      }
    }
    dynamic "required_workflows" {
      for_each = try(each.value.rules.required_workflows, null) != null ? [1] : []
      content {
        dynamic "required_workflow" {
          for_each = each.value.rules.required_workflows != null ? each.value.rules.required_workflows : []
          content {
            repository_id = try(local.github_repository_id[required_workflow.value.repository], required_workflow.value.repository)
            path          = required_workflow.value.path
            ref           = required_workflow.value.ref
          }
        }
      }
    }
    update = try(each.value.rules.update, null)
  }
  target = each.value.target
  dynamic "bypass_actors" {
    for_each = (each.value.bypass_actors != null) ? each.value.bypass_actors : {}
    content {
      actor_id    = bypass_actors.key
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }
  dynamic "conditions" {
    for_each = (length(each.value.include) + length(each.value.exclude) > 0) ? [1] : []
    content {
      ref_name {
        include = [for p in each.value.include :
          substr(p, 0, 1) == "~" ? p : format("refs/%s/%s", each.value.target == "branch" ? "heads" : "tags", p)
        ]
        exclude = [for p in each.value.exclude :
          substr(p, 0, 1) == "~" ? p : format("refs/%s/%s", each.value.target == "branch" ? "heads" : "tags", p)
        ]
      }
      repository_name {
        include = var.mode == "organization" ? ["~ALL"] : [for k, r in module.repo : r.repository.name]
        exclude = []
      }
    }
  }
}

# ========================================================================
# GLOBAL USER ROLE OPTIMIZATION - PROJECT MODE (Teams)
# ========================================================================

# Create teams for global roles with 2+ users in project mode
resource "github_team" "global_role_teams" {
  for_each = local.is_project_mode ? local.optimizable_global_roles : {}

  name        = local.optimized_role_names[each.key]
  description = "Auto-created team for ${each.key} role - ${length(each.value)} global users"
  privacy     = "closed"

  lifecycle {
    prevent_destroy       = false
    create_before_destroy = true
  }
}

# Add global users to role teams in project mode
resource "github_team_membership" "global_role_members" {
  for_each = local.is_project_mode ? {
    for item in flatten([
      for role, users in local.optimizable_global_roles : [
        for user in users : {
          key      = "${role}-${user}"
          team_id  = role
          username = user
          role     = role
        }
      ]
    ]) : item.key => item
  } : {}

  team_id  = github_team.global_role_teams[each.value.role].id
  username = each.value.username
  role     = "member"
}

# ========================================================================
# GLOBAL USER ROLE OPTIMIZATION - ORGANIZATION MODE (Organization Roles)
# ========================================================================

# In organization mode, we use github_organization_role_user (already in organization.tf)
# to assign users directly to organization-wide roles. We just need to add the auto-created
# roles to var.organization_role_assignments which gets processed in organization.tf
