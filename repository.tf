# ========================================================================
# REPOSITORY RESOURCES
# This file contains all repository-related resources previously managed
# by the modules/repository submodule
# ========================================================================

locals {
  # Flatten repositories configuration for resource creation
  # Each repository from local.repositories will be processed

  # Repository roles lookup for rulesets
  repository_roles = {
    "maintain" = 2
    "write"    = 4
    "admin"    = 5
  }

  # Custom properties processing per repository
  repositories_custom_properties = {
    for repo_key, repo_config in local.repositories :
    repo_key => try(repo_config.custom_properties, null) == null ? {} : {
      for i in [
        for n, a in repo_config.custom_properties : {
          property = n
          type     = try(repo_config.custom_properties_types[n], "string")
          value    = flatten([a])
        }
      ] : i.property => i
    }
  }

  # Visibility calculation per repository
  repositories_visibility = {
    for repo_key, repo_config in local.repositories :
    repo_key => (
      try(repo_config.visibility, null) == null && try(repo_config.private, null) != null ?
      (repo_config.private ? "private" : "public") :
      try(repo_config.visibility, null)
    )
  }

  # Security scanning settings per repository
  repositories_security = {
    for repo_key, repo_config in local.repositories :
    repo_key => {
      allowed_scanning = (
        local.repositories_visibility[repo_key] == "public" ||
        try(repo_config.enable_advanced_security, null) == true
      )
      enable_secret_scanning = (
        try(repo_config.enable_secret_scanning, null) == true &&
        (local.repositories_visibility[repo_key] == "public" || try(repo_config.enable_advanced_security, null) == true)
      )
      enable_secret_scanning_push_protection = (
        try(repo_config.enable_secret_scanning_push_protection, null) == true &&
        (local.repositories_visibility[repo_key] == "public" || try(repo_config.enable_advanced_security, null) == true)
      )
    }
  }
}

# ========================================================================
# GITHUB REPOSITORY (Main Resource)
# ========================================================================

resource "github_repository" "repo" {
  for_each = local.repositories

  name                        = format(local.spec, coalesce(try(each.value.alias, null), each.key))
  description                 = try(each.value.description, null)
  homepage_url                = try(each.value.homepage, null)
  private                     = try(each.value.private, null)
  visibility                  = local.repositories_visibility[each.key]
  has_issues                  = try(each.value.has_issues, null)
  has_projects                = try(each.value.has_projects, null)
  has_wiki                    = try(each.value.has_wiki, null)
  has_discussions             = try(each.value.has_discussions, null)
  has_downloads               = try(each.value.has_downloads, null)
  is_template                 = try(each.value.is_template, null)
  allow_merge_commit          = try(each.value.allow_merge_commit, null)
  allow_squash_merge          = try(each.value.allow_squash_merge, null)
  allow_rebase_merge          = try(each.value.allow_rebase_merge, null)
  allow_auto_merge            = try(each.value.allow_auto_merge, null)
  squash_merge_commit_title   = try(each.value.squash_merge_commit_title, null)
  squash_merge_commit_message = try(each.value.squash_merge_commit_message, null)
  merge_commit_title          = try(each.value.merge_commit_title, null)
  merge_commit_message        = try(each.value.merge_commit_message, null)
  delete_branch_on_merge      = try(each.value.delete_branch_on_merge, null)
  auto_init                   = try(each.value.auto_init, null) != null || try(each.value.default_branch, null) != null
  gitignore_template          = try(each.value.gitignore_template, null)
  license_template            = try(each.value.license_template, null)
  archived                    = try(each.value.archived, null)
  archive_on_destroy          = try(each.value.archive_on_destroy, null)
  topics                      = try(each.value.topics, [])
  vulnerability_alerts        = try(each.value.enable_vulnerability_alerts, null)
  allow_update_branch         = try(each.value.allow_update_branch, null)
  web_commit_signoff_required = try(each.value.web_commit_signoff_required, null)

  dynamic "pages" {
    for_each = try(each.value.pages_build_type, null) != null ? [1] : []
    content {
      dynamic "source" {
        for_each = try(each.value.pages_source_branch, null) != null ? [1] : []
        content {
          branch = each.value.pages_source_branch
          path   = try(each.value.pages_source_path, null)
        }
      }
      build_type = each.value.pages_build_type
      cname      = try(each.value.pages_cname, null)
    }
  }

  dynamic "security_and_analysis" {
    for_each = (
      try(each.value.enable_advanced_security, null) != null ||
      try(each.value.enable_secret_scanning, null) != null ||
      try(each.value.enable_secret_scanning_push_protection, null) != null
    ) ? [1] : []
    content {
      dynamic "advanced_security" {
        for_each = try(each.value.enable_advanced_security, null) == true ? [1] : []
        content {
          status = "enabled"
        }
      }
      dynamic "secret_scanning" {
        for_each = local.repositories_security[each.key].enable_secret_scanning ? [1] : []
        content {
          status = "enabled"
        }
      }
      dynamic "secret_scanning_push_protection" {
        for_each = local.repositories_security[each.key].enable_secret_scanning_push_protection ? [1] : []
        content {
          status = "enabled"
        }
      }
    }
  }

  dynamic "template" {
    for_each = try(each.value.template, null) != null ? [1] : []
    content {
      owner                = try(element(split("/", each.value.template), 0), null)
      repository           = try(element(split("/", each.value.template), 1), null)
      include_all_branches = try(each.value.template_include_all_branches, null)
    }
  }

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      topics,
      description,
      homepage_url,
    ]

    precondition {
      condition     = try(format(local.spec, each.key), each.key) != ""
      error_message = "Repository name cannot be empty"
    }

    precondition {
      condition     = can(regex("^[a-zA-Z0-9._-]+$", try(format(local.spec, each.key), each.key)))
      error_message = "Repository name can only contain alphanumeric characters, hyphens, underscores, and periods"
    }
  }
}

# ========================================================================
# REPOSITORY CONFIGURATION RESOURCES
# ========================================================================

# Actions repository access level
resource "github_actions_repository_access_level" "repo" {
  for_each = {
    for repo_key, repo_config in local.repositories :
    repo_key => repo_config
    if try(repo_config.actions_access_level, null) != null
  }

  repository   = github_repository.repo[each.key].name
  access_level = each.value.actions_access_level
}

# Actions repository permissions
resource "github_actions_repository_permissions" "repo" {
  for_each = {
    for repo_key, repo_config in local.repositories :
    repo_key => repo_config
    if try(repo_config.enable_actions, null) != null || try(repo_config.actions_allowed_policy, null) != null
  }

  repository      = github_repository.repo[each.key].name
  enabled         = try(each.value.enable_actions, null)
  allowed_actions = try(each.value.enable_actions, null) == false ? null : try(each.value.actions_allowed_policy, null)

  dynamic "allowed_actions_config" {
    for_each = (try(each.value.enable_actions, null) == false ? null : try(each.value.actions_allowed_policy, null)) == "selected" ? [1] : []
    content {
      github_owned_allowed = try(each.value.actions_allowed_github, true)
      patterns_allowed     = try(each.value.actions_allowed_patterns, [])
      verified_allowed     = try(each.value.actions_allowed_verified, null)
    }
  }
}

# Repository collaborators (teams and users)
resource "github_repository_collaborators" "repo" {
  for_each = {
    for repo_key, repo_config in local.repositories :
    repo_key => repo_config
    if try(repo_config.teams, null) != null || try(repo_config.users, null) != null
  }

  repository = github_repository.repo[each.key].name

  dynamic "user" {
    for_each = try(each.value.users, {})
    content {
      permission = user.value
      username   = user.key
    }
  }

  dynamic "team" {
    for_each = try(each.value.teams, {})
    content {
      permission = team.value
      team_id    = team.key
    }
  }
}

# Branch default
resource "github_branch_default" "repo" {
  for_each = {
    for repo_key, repo_config in local.repositories :
    repo_key => repo_config
    if try(repo_config.default_branch, null) != null
  }

  repository = github_repository.repo[each.key].name
  branch     = each.value.default_branch
}

# Branches
resource "github_branch" "repo" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for branch_name, branch_config in try(repo_config.branches, {}) :
      "${repo_key}/${branch_name}" => {
        repository    = repo_key
        branch        = branch_name
        source_branch = try(branch_config.source_branch, null)
        source_sha    = try(branch_config.source_sha, null)
      }
    }
  ]...)

  repository    = github_repository.repo[each.value.repository].name
  branch        = each.value.branch
  source_branch = each.value.source_branch
  source_sha    = each.value.source_sha
}

# Repository dependabot security updates
resource "github_repository_dependabot_security_updates" "repo" {
  for_each = {
    for repo_key, repo_config in local.repositories :
    repo_key => repo_config
    if try(repo_config.enable_dependabot_security_updates, null) != null
  }

  repository = github_repository.repo[each.key].name
  enabled    = each.value.enable_dependabot_security_updates
}

# Repository autolink references
resource "github_repository_autolink_reference" "repo" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for autolink_key, autolink_config in try(repo_config.autolink_references, {}) :
      "${repo_key}/${autolink_key}" => {
        repository      = repo_key
        key_prefix      = autolink_config.key_prefix
        target_url      = autolink_config.target_url
        is_alphanumeric = autolink_config.is_alphanumeric
      }
    }
  ]...)

  repository          = github_repository.repo[each.value.repository].name
  key_prefix          = each.value.key_prefix
  target_url_template = each.value.target_url
}

# Repository custom properties
resource "github_repository_custom_property" "repo" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for prop_name, prop_config in local.repositories_custom_properties[repo_key] :
      "${repo_key}/${prop_name}" => {
        repository     = repo_key
        property_name  = prop_name
        property_type  = prop_config.type
        property_value = prop_config.value
      }
    }
  ]...)

  repository     = github_repository.repo[each.value.repository].name
  property_name  = each.value.property_name
  property_type  = each.value.property_type
  property_value = each.value.property_value
}

# Issue labels
resource "github_issue_labels" "repo" {
  for_each = {
    for repo_key, repo_config in local.repositories :
    repo_key => repo_config
    if try(repo_config.issue_labels, null) != null
  }

  repository = github_repository.repo[each.key].name

  dynamic "label" {
    for_each = each.value.issue_labels
    content {
      name        = label.key
      color       = try(each.value.issue_labels_colors[label.key], null) != null ? each.value.issue_labels_colors[label.key] : substr(sha256(label.key), 0, 6)
      description = label.value
    }
  }
}

# ========================================================================
# SECRETS AND VARIABLES
# ========================================================================

# Actions secrets (plaintext)
resource "github_actions_secret" "plaintext" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for secret_name, secret_value in try(repo_config.secrets, {}) :
      "${repo_key}/${secret_name}" => {
        repository   = repo_key
        secret_name  = secret_name
        secret_value = secret_value
      }
    }
  ]...)

  repository      = github_repository.repo[each.value.repository].name
  secret_name     = each.value.secret_name
  plaintext_value = each.value.secret_value
}

# Actions secrets (encrypted)
resource "github_actions_secret" "encrypted" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for secret_name, secret_value in try(repo_config.secrets_encrypted, {}) :
      "${repo_key}/${secret_name}" => {
        repository   = repo_key
        secret_name  = secret_name
        secret_value = secret_value
      }
    }
  ]...)

  repository      = github_repository.repo[each.value.repository].name
  secret_name     = each.value.secret_name
  encrypted_value = each.value.secret_value
}

# Actions variables
resource "github_actions_variable" "repo" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for var_name, var_value in try(repo_config.variables, {}) :
      "${repo_key}/${var_name}" => {
        repository    = repo_key
        variable_name = var_name
        value         = var_value
      }
    }
  ]...)

  repository    = github_repository.repo[each.value.repository].name
  variable_name = each.value.variable_name
  value         = each.value.value
}

# Dependabot secrets (plaintext)
resource "github_dependabot_secret" "plaintext" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for secret_name, secret_value in(
        try(repo_config.dependabot_secrets, null) != null ?
        repo_config.dependabot_secrets :
        (try(repo_config.dependabot_copy_secrets, false) ? try(repo_config.secrets, {}) : {})
      ) :
      "${repo_key}/${secret_name}" => {
        repository   = repo_key
        secret_name  = secret_name
        secret_value = secret_value
      }
    }
  ]...)

  repository      = github_repository.repo[each.value.repository].name
  secret_name     = each.value.secret_name
  plaintext_value = each.value.secret_value
}

# Dependabot secrets (encrypted)
resource "github_dependabot_secret" "encrypted" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for secret_name, secret_value in(
        try(repo_config.dependabot_secrets_encrypted, null) != null ?
        repo_config.dependabot_secrets_encrypted :
        (try(repo_config.dependabot_copy_secrets, false) ? try(repo_config.secrets_encrypted, {}) : {})
      ) :
      "${repo_key}/${secret_name}" => {
        repository   = repo_key
        secret_name  = secret_name
        secret_value = secret_value
      }
    }
  ]...)

  repository      = github_repository.repo[each.value.repository].name
  secret_name     = each.value.secret_name
  encrypted_value = each.value.secret_value
}

# ========================================================================
# DEPLOY KEYS
# ========================================================================

# TLS private keys (auto-generated when public_key is not provided)
resource "tls_private_key" "repo" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for key_name, key_config in try(repo_config.deploy_keys, {}) :
      "${repo_key}/${key_name}" => {
        repository = repo_key
        key_name   = key_name
      }
      if try(key_config.public_key, null) == null
    }
  ]...)

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Repository deploy keys
resource "github_repository_deploy_key" "repo" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for key_name, key_config in try(repo_config.deploy_keys, {}) :
      "${repo_key}/${key_name}" => {
        repository = repo_key
        key_name   = key_name
        public_key = key_config.public_key
        read_only  = try(key_config.read_only, true)
      }
    }
  ]...)

  repository = github_repository.repo[each.value.repository].name
  title      = each.value.key_name
  key = (
    each.value.public_key != null ?
    each.value.public_key :
    tls_private_key.repo["${each.value.repository}/${each.value.key_name}"].public_key_openssh
  )
  read_only = each.value.read_only
}

# Local files for auto-generated private keys
resource "null_resource" "create_deploy_keys_folder" {
  for_each = {
    for repo_key, repo_config in local.repositories :
    repo_key => repo_config
    if try(repo_config.deploy_keys_path, null) != null
  }

  provisioner "local-exec" {
    command = "mkdir -p ${each.value.deploy_keys_path}"
  }
}

resource "local_file" "private_key_file" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for key_name, key_config in try(repo_config.deploy_keys, {}) :
      "${repo_key}/${key_name}" => {
        repository       = repo_key
        key_name         = key_name
        deploy_keys_path = repo_config.deploy_keys_path
      }
      if try(repo_config.deploy_keys_path, null) != null && try(key_config.public_key, null) == null
    }
  ]...)

  filename = "${each.value.deploy_keys_path}/${github_repository.repo[each.value.repository].name}-${each.value.key_name}.pem"
  content  = tls_private_key.repo["${each.value.repository}/${each.value.key_name}"].private_key_openssh

  depends_on = [null_resource.create_deploy_keys_folder]
}

# ========================================================================
# ENVIRONMENTS
# ========================================================================

# Repository environments
resource "github_repository_environment" "repo" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for env_name, env_config in try(repo_config.environments, {}) :
      "${repo_key}/${env_name}" => {
        repository                                  = repo_key
        environment                                 = env_name
        wait_timer                                  = try(env_config.wait_timer, null)
        can_admins_bypass                           = try(env_config.can_admins_bypass, true)
        prevent_self_review                         = try(env_config.prevent_self_review, false)
        reviewers_teams                             = try(env_config.reviewers_teams, null)
        reviewers_users                             = try(env_config.reviewers_users, null)
        deployment_branch_policy_protected_branches = try(env_config.deployment_branch_policy.protected_branches, null)
        deployment_branch_policy_custom_policies    = try(env_config.deployment_branch_policy.custom_branch_policies, null)
      }
    }
  ]...)

  repository          = github_repository.repo[each.value.repository].name
  environment         = each.value.environment
  wait_timer          = each.value.wait_timer
  can_admins_bypass   = each.value.can_admins_bypass
  prevent_self_review = each.value.prevent_self_review

  dynamic "reviewers" {
    for_each = (each.value.reviewers_teams != null || each.value.reviewers_users != null) ? [1] : []
    content {
      teams = try(each.value.reviewers_teams, [])
      users = try(each.value.reviewers_users, [])
    }
  }

  dynamic "deployment_branch_policy" {
    for_each = (each.value.deployment_branch_policy_protected_branches != null || each.value.deployment_branch_policy_custom_policies != null) ? [1] : []
    content {
      protected_branches     = try(each.value.deployment_branch_policy_protected_branches, false)
      custom_branch_policies = try(each.value.deployment_branch_policy_custom_policies, false)
    }
  }
}

# Repository environment deployment policies
# NOTE: custom_branch_policies in variables.tf is a boolean, not a list of patterns
# If detailed branch patterns are needed, this should be expanded in the future
# resource "github_repository_environment_deployment_policy" "repo" {
#   for_each = ...
# }

# Environment secrets (plaintext)
resource "github_actions_environment_secret" "plaintext" {
  for_each = merge(flatten([
    for repo_key, repo_config in local.repositories : [
      for env_name, env_config in try(repo_config.environments, {}) : {
        for secret_name, secret_value in try(env_config.secrets, {}) :
        "${repo_key}/${env_name}/${secret_name}" => {
          repository  = repo_key
          environment = env_name
          secret_name = secret_name
          value       = secret_value
        }
      }
    ]
  ])...)

  repository      = github_repository.repo[each.value.repository].name
  environment     = github_repository_environment.repo["${each.value.repository}/${each.value.environment}"].environment
  secret_name     = each.value.secret_name
  plaintext_value = each.value.value
}

# Environment secrets (encrypted)
resource "github_actions_environment_secret" "encrypted" {
  for_each = merge(flatten([
    for repo_key, repo_config in local.repositories : [
      for env_name, env_config in try(repo_config.environments, {}) : {
        for secret_name, secret_value in try(env_config.secrets_encrypted, {}) :
        "${repo_key}/${env_name}/${secret_name}" => {
          repository  = repo_key
          environment = env_name
          secret_name = secret_name
          value       = secret_value
        }
      }
    ]
  ])...)

  repository      = github_repository.repo[each.value.repository].name
  environment     = github_repository_environment.repo["${each.value.repository}/${each.value.environment}"].environment
  secret_name     = each.value.secret_name
  encrypted_value = each.value.value
}

# Environment variables
resource "github_actions_environment_variable" "repo" {
  for_each = merge(flatten([
    for repo_key, repo_config in local.repositories : [
      for env_name, env_config in try(repo_config.environments, {}) : {
        for var_name, var_value in try(env_config.variables, {}) :
        "${repo_key}/${env_name}/${var_name}" => {
          repository    = repo_key
          environment   = env_name
          variable_name = var_name
          value         = var_value
        }
      }
    ]
  ])...)

  repository    = github_repository.repo[each.value.repository].name
  environment   = github_repository_environment.repo["${each.value.repository}/${each.value.environment}"].environment
  variable_name = each.value.variable_name
  value         = each.value.value

  depends_on = [github_repository_environment.repo]
}

# ========================================================================
# FILES
# ========================================================================

resource "github_repository_file" "repo" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for file_config in try(repo_config.files, []) :
      "${repo_key}/${sha1(format("%s:%s", coalesce(try(file_config.branch, null), "_default_"), file_config.file))}" => {
        repository                      = repo_key
        file                            = file_config.file
        content                         = try(file_config.from_file, null) != null ? file(file_config.from_file) : try(file_config.content, null)
        branch                          = try(file_config.branch, null)
        commit_author                   = try(file_config.commit_author, null)
        commit_email                    = try(file_config.commit_email, null)
        commit_message                  = try(file_config.commit_message, null)
        overwrite_on_create             = try(file_config.overwrite_on_create, null)
        autocreate_branch               = try(file_config.autocreate_branch, null)
        autocreate_branch_source_branch = try(file_config.autocreate_branch_source_branch, null)
        autocreate_branch_source_sha    = try(file_config.autocreate_branch_source_sha, null)
      }
    }
  ]...)

  repository                      = github_repository.repo[each.value.repository].name
  file                            = each.value.file
  content                         = each.value.content
  branch                          = each.value.branch
  commit_author                   = each.value.commit_author
  commit_email                    = each.value.commit_email
  commit_message                  = each.value.commit_message
  overwrite_on_create             = each.value.overwrite_on_create
  autocreate_branch               = each.value.autocreate_branch
  autocreate_branch_source_branch = each.value.autocreate_branch_source_branch
  autocreate_branch_source_sha    = each.value.autocreate_branch_source_sha
}

# ========================================================================
# WEBHOOKS
# ========================================================================

resource "github_repository_webhook" "repo" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for webhook_key, webhook_config in try(repo_config.webhooks, {}) :
      "${repo_key}/${webhook_key}" => {
        repository   = repo_key
        url          = webhook_config.url
        content_type = webhook_config.content_type
        insecure_ssl = try(webhook_config.insecure_ssl, false)
        secret       = try(webhook_config.secret, null)
        active       = try(webhook_config.active, true)
        events       = webhook_config.events
      }
    }
  ]...)

  repository = github_repository.repo[each.value.repository].name
  active     = each.value.active

  configuration {
    url          = each.value.url
    content_type = each.value.content_type
    insecure_ssl = each.value.insecure_ssl
    secret       = each.value.secret
  }

  events = each.value.events
}

# ========================================================================
# RULESETS
# ========================================================================

resource "github_repository_ruleset" "repo" {
  for_each = merge([
    for repo_key, repo_config in local.repositories : {
      for ruleset_name, ruleset_config in try(repo_config.rulesets, {}) :
      "${repo_key}/${ruleset_name}" => merge(
        {
          repository  = repo_key
          name        = ruleset_name
          enforcement = try(ruleset_config.enforcement, "active")
          target      = try(ruleset_config.target, "branch")
        },
        ruleset_config
      )
    }
  ]...)

  repository  = github_repository.repo[each.value.repository].name
  name        = each.value.name
  enforcement = each.value.enforcement
  target      = each.value.target

  dynamic "conditions" {
    for_each = (length(try(each.value.include, [])) + length(try(each.value.exclude, [])) > 0) ? [1] : []
    content {
      ref_name {
        include = [for p in try(each.value.include, []) :
          substr(p, 0, 1) == "~" ? p : format("refs/%s/%s", try(each.value.target, "branch") == "branch" ? "heads" : "tags", p)
        ]
        exclude = [for p in try(each.value.exclude, []) :
          substr(p, 0, 1) == "~" ? p : format("refs/%s/%s", try(each.value.target, "branch") == "branch" ? "heads" : "tags", p)
        ]
      }
    }
  }

  dynamic "bypass_actors" {
    for_each = try(each.value.bypass_roles, [])
    content {
      actor_type  = "RepositoryRole"
      actor_id    = lookup(local.repository_roles, bypass_actors.value, null)
      bypass_mode = try(each.value.bypass_mode, "always")
    }
  }

  dynamic "bypass_actors" {
    for_each = try(each.value.bypass_teams, [])
    content {
      actor_type  = "Team"
      actor_id    = bypass_actors.value
      bypass_mode = try(each.value.bypass_mode, "always")
    }
  }

  dynamic "bypass_actors" {
    for_each = try(each.value.bypass_integration, [])
    content {
      actor_type  = "Integration"
      actor_id    = bypass_actors.value
      bypass_mode = try(each.value.bypass_mode, "always")
    }
  }

  dynamic "bypass_actors" {
    for_each = try(each.value.bypass_organization_admin, false) == true ? [1] : []
    content {
      actor_type  = "OrganizationAdmin"
      actor_id    = 0
      bypass_mode = try(each.value.bypass_mode, "always")
    }
  }

  rules {
    dynamic "branch_name_pattern" {
      for_each = try(each.value.target, "branch") == "branch" && try(each.value.regex_target, null) != null ? [1] : []
      content {
        operator = "regex"
        pattern  = each.value.regex_target
      }
    }

    dynamic "tag_name_pattern" {
      for_each = try(each.value.target, "branch") == "tag" && try(each.value.regex_target, null) != null ? [1] : []
      content {
        operator = "regex"
        pattern  = each.value.regex_target
      }
    }

    dynamic "commit_author_email_pattern" {
      for_each = try(each.value.regex_commit_author_email, null) != null ? [1] : []
      content {
        operator = "regex"
        pattern  = each.value.regex_commit_author_email
      }
    }

    dynamic "commit_message_pattern" {
      for_each = try(each.value.regex_commit_message, null) != null ? [1] : []
      content {
        operator = "regex"
        pattern  = each.value.regex_commit_message
      }
    }

    dynamic "committer_email_pattern" {
      for_each = try(each.value.regex_committer_email, null) != null ? [1] : []
      content {
        operator = "regex"
        pattern  = each.value.regex_committer_email
      }
    }

    creation         = try(each.value.forbidden_creation, null)
    deletion         = try(each.value.forbidden_deletion, null)
    update           = try(each.value.forbidden_update, null)
    non_fast_forward = try(each.value.forbidden_fast_forward, null)

    dynamic "pull_request" {
      for_each = (
        try(each.value.dismiss_pr_stale_reviews_on_push, null) != null ||
        try(each.value.required_pr_code_owner_review, null) != null ||
        try(each.value.required_pr_last_push_approval, null) != null ||
        try(each.value.required_pr_approving_review_count, null) != null ||
        try(each.value.required_pr_review_thread_resolution, null) != null
      ) ? [1] : []
      content {
        dismiss_stale_reviews_on_push     = try(each.value.dismiss_pr_stale_reviews_on_push, null)
        require_code_owner_review         = try(each.value.required_pr_code_owner_review, null)
        require_last_push_approval        = try(each.value.required_pr_last_push_approval, null)
        required_approving_review_count   = try(each.value.required_pr_approving_review_count, null)
        required_review_thread_resolution = try(each.value.required_pr_review_thread_resolution, null)
      }
    }

    dynamic "required_deployments" {
      for_each = try(each.value.required_deployment_environments, null) != null && length(try(each.value.required_deployment_environments, [])) > 0 ? [1] : []
      content {
        required_deployment_environments = each.value.required_deployment_environments
      }
    }

    required_linear_history = try(each.value.required_linear_history, null)
    required_signatures     = try(each.value.required_signatures, null)

    dynamic "required_status_checks" {
      for_each = try(each.value.required_checks, null) != null && length(try(each.value.required_checks, [])) > 0 ? [1] : []
      content {
        dynamic "required_check" {
          for_each = each.value.required_checks
          content {
            context = required_check.value
          }
        }
      }
    }

    dynamic "required_code_scanning" {
      for_each = length(try(each.value.required_code_scanning, {})) > 0 ? [1] : []
      content {
        dynamic "required_code_scanning_tool" {
          for_each = each.value.required_code_scanning
          content {
            tool                      = required_code_scanning_tool.key
            security_alerts_threshold = try(split(":", required_code_scanning_tool.value)[0], "none")
            alerts_threshold          = try(split(":", required_code_scanning_tool.value)[1], "none")
          }
        }
      }
    }
  }

  depends_on = [github_repository_environment.repo]
}
