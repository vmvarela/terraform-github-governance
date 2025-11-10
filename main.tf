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

  # merge settings, each repository and defaults
  repositories = { for repo, data in var.repositories : coalesce(try(data.alias, null), repo) => merge(
    { description = try(data.description, null) },
    { for k in local.coalesce_keys : k => try(coalesce(lookup(local.settings, k, null), lookup(data, k, null), lookup(var.defaults, k, null)), null) },
    { for k in local.union_keys : k =>
      length(setunion(
        [],
        try(lookup(data, k, null), null) != null ? try(lookup(data, k, []), []) : [],
        try(lookup(local.settings, k, null), null) != null ? try(lookup(local.settings, k, []), []) : []
      )) > 0 ?
      setunion(
        try(lookup(data, k, null), null) != null ? try(lookup(data, k, []), []) : [],
        try(lookup(local.settings, k, null), null) != null ? try(lookup(local.settings, k, []), []) : []
      ) :
      try(lookup(var.defaults, k, []), [])
    },
    { for k in local.merge_keys : k =>
      length(merge(
        try(lookup(data, k, null), null) != null ? try(lookup(data, k, {}), {}) : {},
        try(lookup(local.settings, k, null), null) != null ? try(lookup(local.settings, k, {}), {}) : {}
      )) > 0 ?
      merge(
        try(lookup(data, k, null), null) != null ? try(lookup(data, k, {}), {}) : {},
        try(lookup(local.settings, k, null), null) != null ? try(lookup(local.settings, k, {}), {}) : {}
      ) :
      try(lookup(var.defaults, k, {}), {})
    }
  ) }

  github_org        = var.mode == "organization" ? var.name : var.github_org
  info_repositories = var.info_repositories != null ? var.info_repositories : try(data.github_repositories.all[0], null)

  # Map of repository name to ID from existing repositories in the organization
  github_repository_id_external = { for r in try(local.info_repositories.names, []) :
    r => element(local.info_repositories.repo_ids, index(local.info_repositories.names, r))
  }

  # Map of repository name to ID from repositories managed by this module
  github_repository_id_managed = { for name, repo in module.repo :
    repo.repository.name => repo.repository.repo_id
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
  project_repository_ids = local.is_project_mode ? [for k, r in module.repo : r.repository.repo_id] : []
}

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

# Validate organization plan for features that require paid plans
check "organization_plan_validation" {
  assert {
    condition = length(var.webhooks) == 0 || local.github_plan != "free"

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
    condition = length(var.rulesets) == 0 || local.github_plan != "free"

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
    condition = length(var.repository_roles) == 0 || contains(["enterprise", "enterprise_cloud"], local.github_plan)

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

# organization_settings
resource "github_organization_settings" "this" {
  count                                                        = var.mode == "organization" ? 1 : 0
  name                                                         = try(var.settings.display_name, null)
  description                                                  = try(var.settings.description, null)
  billing_email                                                = try(var.settings.billing_email, null)
  company                                                      = try(var.settings.company, null)
  blog                                                         = try(var.settings.blog, null)
  email                                                        = try(var.settings.email, null)
  twitter_username                                             = try(var.settings.twitter_username, null)
  location                                                     = try(var.settings.location, null)
  has_organization_projects                                    = try(var.settings.has_organization_projects, null)
  default_repository_permission                                = try(var.settings.default_repository_permission, null)
  members_can_create_repositories                              = try(var.settings.members_can_create_repositories, null)
  members_can_create_public_repositories                       = try(var.settings.members_can_create_public_repositories, null)
  members_can_create_private_repositories                      = try(var.settings.members_can_create_private_repositories, null)
  members_can_create_internal_repositories                     = try(var.settings.members_can_create_internal_repositories, null)
  members_can_create_pages                                     = try(var.settings.members_can_create_pages, null)
  members_can_create_public_pages                              = try(var.settings.members_can_create_public_pages, null)
  members_can_create_private_pages                             = try(var.settings.members_can_create_private_pages, null)
  members_can_fork_private_repositories                        = try(var.settings.members_can_fork_private_repositories, null)
  has_repository_projects                                      = try(coalesce(local.settings.has_projects, local.defaults.has_projects), null)
  advanced_security_enabled_for_new_repositories               = try(coalesce(local.settings.enable_advanced_security, local.defaults.enable_advanced_security), null)
  dependabot_security_updates_enabled_for_new_repositories     = try(coalesce(local.settings.enable_dependabot_security_updates, local.defaults.enable_dependabot_security_updates), null)
  secret_scanning_enabled_for_new_repositories                 = try(coalesce(local.settings.enable_secret_scanning, local.defaults.enable_secret_scanning), null)
  secret_scanning_push_protection_enabled_for_new_repositories = try(coalesce(local.settings.enable_secret_scanning_push_protection, local.defaults.enable_secret_scanning_push_protection), null)
  dependabot_alerts_enabled_for_new_repositories               = try(coalesce(local.settings.enable_vulnerability_alerts, local.defaults.enable_vulnerability_alerts), null)
  dependency_graph_enabled_for_new_repositories                = try(coalesce(local.settings.enable_dependency_graph, local.defaults.enable_dependency_graph), null)
  web_commit_signoff_required                                  = try(coalesce(local.settings.web_commit_signoff_required, local.defaults.web_commit_signoff_required), null)

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      # Ignore changes to these fields that are often modified outside Terraform
      name,
      description,
    ]
  }
}

module "repo" {
  for_each                               = local.repositories
  source                                 = "./modules/repository"
  actions_access_level                   = each.value.actions_access_level
  actions_allowed_github                 = each.value.actions_allowed_github
  actions_allowed_patterns               = each.value.actions_allowed_patterns
  actions_allowed_policy                 = each.value.actions_allowed_policy
  actions_allowed_verified               = each.value.actions_allowed_verified
  alias                                  = try(each.value.alias, each.key)
  allow_auto_merge                       = each.value.allow_auto_merge
  allow_merge_commit                     = each.value.allow_merge_commit
  allow_rebase_merge                     = each.value.allow_rebase_merge
  allow_squash_merge                     = each.value.allow_squash_merge
  allow_update_branch                    = each.value.allow_update_branch
  archived                               = each.value.archived
  archive_on_destroy                     = each.value.archive_on_destroy
  autolink_references                    = each.value.autolink_references
  auto_init                              = each.value.auto_init
  branches                               = each.value.branches
  custom_properties                      = each.value.custom_properties
  custom_properties_types                = each.value.custom_properties_types
  default_branch                         = each.value.default_branch
  delete_branch_on_merge                 = each.value.delete_branch_on_merge
  dependabot_copy_secrets                = each.value.dependabot_copy_secrets
  dependabot_secrets                     = each.value.dependabot_secrets
  dependabot_secrets_encrypted           = each.value.dependabot_secrets_encrypted
  deploy_keys                            = each.value.deploy_keys
  deploy_keys_path                       = each.value.deploy_keys_path
  description                            = try(each.value.description, null)
  enable_actions                         = each.value.enable_actions
  enable_advanced_security               = each.value.enable_advanced_security
  enable_secret_scanning                 = each.value.enable_secret_scanning
  enable_secret_scanning_push_protection = each.value.enable_secret_scanning_push_protection
  enable_vulnerability_alerts            = each.value.enable_vulnerability_alerts
  enable_dependabot_security_updates     = each.value.enable_dependabot_security_updates
  environments                           = each.value.environments
  files                                  = each.value.files
  gitignore_template                     = each.value.gitignore_template
  has_issues                             = each.value.has_issues
  has_projects                           = each.value.has_projects
  has_wiki                               = each.value.has_wiki
  homepage                               = each.value.homepage
  is_template                            = each.value.is_template
  issue_labels                           = each.value.issue_labels
  issue_labels_colors                    = each.value.issue_labels_colors
  license_template                       = each.value.license_template
  merge_commit_message                   = each.value.merge_commit_message
  merge_commit_title                     = each.value.merge_commit_title
  name                                   = try(format(local.spec, each.key), each.key)
  pages_build_type                       = each.value.pages_build_type
  pages_cname                            = each.value.pages_cname
  pages_source_branch                    = each.value.pages_source_branch
  pages_source_path                      = each.value.pages_source_path
  private                                = each.value.private
  rulesets                               = each.value.rulesets
  secrets                                = each.value.secrets
  secrets_encrypted                      = each.value.secrets_encrypted
  squash_merge_commit_message            = each.value.squash_merge_commit_message
  squash_merge_commit_title              = each.value.squash_merge_commit_title
  teams                                  = each.value.teams
  template                               = each.value.template
  template_include_all_branches          = each.value.template_include_all_branches
  topics                                 = each.value.topics
  users                                  = each.value.users
  variables                              = each.value.variables
  visibility                             = each.value.visibility
  web_commit_signoff_required            = each.value.web_commit_signoff_required
  webhooks                               = each.value.webhooks
}

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
  for_each                = coalesce(var.dependabot_secrets_encrypted, (var.dependabot_copy_secrets ? var.secrets_encrypted : {}), {})
  secret_name             = upper(replace(format(local.spec, each.key), "-", "_"))
  encrypted_value         = each.value
  visibility              = local.is_project_mode ? "selected" : "all"
  selected_repository_ids = local.is_project_mode ? local.project_repository_ids : null
}

# organization_ruleset
resource "github_organization_ruleset" "this" {
  for_each    = coalesce(var.rulesets, {})
  name        = format(local.spec, each.key)
  enforcement = each.value.enforcement

  lifecycle {
    # Prevent accidental destruction of critical rulesets
    prevent_destroy = false
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

  # Ensure repositories are resolved before creating runner group
  depends_on = [module.repo]
}

# organization_repository_role
# NOTE: Using deprecated github_organization_custom_role due to provider bug in github_organization_repository_role
# TODO: Migrate to github_organization_repository_role when provider issue is fixed
resource "github_organization_custom_role" "this" {
  for_each    = var.mode == "organization" ? var.repository_roles : {}
  name        = each.key
  description = each.value.description
  base_role   = each.value.base_role
  permissions = each.value.permissions
}

# organization_webhook
# NOTE: Organization webhooks require GitHub Team or Enterprise plan.
# For GitHub Free organizations, use repository-level webhooks instead.
resource "github_organization_webhook" "this" {
  for_each = var.mode == "organization" ? var.webhooks : {}
  active   = true
  configuration {
    url          = each.value.url
    content_type = each.value.content_type
    insecure_ssl = each.value.insecure_ssl
    secret       = each.value.secret
  }
  events = each.value.events
}
