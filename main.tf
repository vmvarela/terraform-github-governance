# Governance module - orchestrates multiple repositories with shared configuration

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
  }

  # Process each repository: merge preset with overrides
  processed_repositories = {
    for key, repo in var.repositories : key => merge(
      {
        # Keep the final merged preset for reference/debugging
        preset_config = merge(
          local.preset_base_default,
          try(var.presets[repo.preset], var.presets["default"], {})
        )
      },
      {
        # Determine the final repository name
        # Always apply repository_naming format, using explicit name if provided, otherwise use key
        name = format(var.repository_naming, coalesce(repo.name, key))

        # Get preset for reference
        preset = merge(local.preset_base_default, try(var.presets[repo.preset], var.presets["default"], {}))

        # Merge properties: preset properties + workspace + repo overrides
        properties = merge(
          try(local.preset_base_default.properties, {}),
          try(try(var.presets[repo.preset], var.presets["default"]).properties, {}),
          { workspace = var.workspace },
          try(repo.properties, {})
        )

        # Merge core configuration (repo overrides preset)
        description = trimspace(join("", compact([
          try(repo.description, null),
          try(try(var.presets[repo.preset], var.presets["default"]).description, null)
        ])))
        visibility     = coalesce(try(repo.visibility, null), try(try(var.presets[repo.preset], var.presets["default"]).visibility, null), local.preset_base_default.visibility)
        default_branch = coalesce(try(repo.default_branch, null), try(try(var.presets[repo.preset], var.presets["default"]).default_branch, null), local.preset_base_default.default_branch)
        topics         = coalesce(try(repo.topics, null), try(try(var.presets[repo.preset], var.presets["default"]).topics, null), local.preset_base_default.topics)

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
        protected_branches      = coalesce(try(repo.protected_branches, null), try(try(var.presets[repo.preset], var.presets["default"]).protected_branches, null), local.preset_base_default.protected_branches)
        allow_bypass            = coalesce(try(repo.allow_bypass, null), try(try(var.presets[repo.preset], var.presets["default"]).allow_bypass, null), local.preset_base_default.allow_bypass)
        required_approvals      = coalesce(try(repo.required_approvals, null), try(try(var.presets[repo.preset], var.presets["default"]).required_approvals, null), local.preset_base_default.required_approvals)
        required_checks         = coalesce(try(repo.required_checks, null), try(try(var.presets[repo.preset], var.presets["default"]).required_checks, null), local.preset_base_default.required_checks)
        prevent_force_push      = coalesce(try(repo.prevent_force_push, null), try(try(var.presets[repo.preset], var.presets["default"]).prevent_force_push, null), local.preset_base_default.prevent_force_push)
        prevent_branch_deletion = coalesce(try(repo.prevent_branch_deletion, null), try(try(var.presets[repo.preset], var.presets["default"]).prevent_branch_deletion, null), local.preset_base_default.prevent_branch_deletion)

        # Store the preset name for reference
        preset_name = repo.preset
      }
    )
  }
}

# Create each repository using the repository module
module "repositories" {
  for_each = local.processed_repositories
  source   = "./modules/repository"

  # Core configuration
  name           = each.value.name
  organization   = var.organization
  workspace      = var.workspace
  description    = each.value.description
  visibility     = each.value.visibility
  default_branch = each.value.default_branch
  topics         = each.value.topics
  properties     = each.value.properties

  # Template
  is_template = each.value.is_template
  template    = each.value.template

  # Access & Permissions
  permissions   = each.value.permissions
  deploy_keys   = each.value.deploy_keys
  allowed_roles = each.value.allowed_roles

  # Automation (Global)
  webhooks = each.value.webhooks
  repository_secrets = try(each.value.repository_secrets, null) != null ? {
    for k, v in each.value.repository_secrets : k => (
      can(try(v.value, null)) ? v.value : v
    )
  } : null
  repository_variables = each.value.repository_variables

  # CI/CD Environments
  environments = each.value.environments

  # Branch Protection (flattened)
  protected_branches      = each.value.protected_branches
  allow_bypass            = each.value.allow_bypass
  required_approvals      = each.value.required_approvals
  required_checks         = each.value.required_checks
  prevent_force_push      = each.value.prevent_force_push
  prevent_branch_deletion = each.value.prevent_branch_deletion

  # Pre-fetched IDs for actors (bypass + required_approvers)
  github_team_ids = local.github_team_ids
  github_user_ids = local.github_user_ids
  github_app_ids  = local.github_app_ids
}
