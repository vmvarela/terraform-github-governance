resource "github_repository" "this" {
  name        = var.name
  description = var.description
  visibility  = coalesce(var.visibility, "private")
  auto_init   = true
  topics      = var.topics
  is_template = var.is_template

  # Template (if provided)
  dynamic "template" {
    for_each = var.template == null ? [] : [var.template]
    content {
      owner                = split("/", template.value.repository)[0]
      repository           = split("/", template.value.repository)[1]
      include_all_branches = template.value.include_all_branches
    }
  }

  # Validate that all referenced teams, users and apps are provided by the parent module
  lifecycle {
    precondition {
      condition = alltrue([
        for slug in concat(local.bypass_team_slugs, local.env_team_slugs) :
        contains(keys(var.github_team_ids), slug)
      ])
      error_message = "Some team slugs are not provided. Missing: ${join(", ", [
        for slug in concat(local.bypass_team_slugs, local.env_team_slugs) :
        slug if !contains(keys(var.github_team_ids), slug)
      ])}. Parent module must provide all team IDs in github_team_ids variable."
    }

    precondition {
      condition = alltrue([
        for login in local.env_user_logins :
        contains(keys(var.github_user_ids), login)
      ])
      error_message = "Some user logins are not provided. Missing: ${join(", ", [
        for login in local.env_user_logins :
        login if !contains(keys(var.github_user_ids), login)
      ])}. Parent module must provide all user IDs in github_user_ids variable."
    }

    precondition {
      condition = alltrue([
        for slug in [for actor in var.allow_bypass : split(":", actor)[1] if startswith(actor, "app:")] :
        contains(keys(var.github_app_ids), slug)
      ])
      error_message = "Some app slugs are not provided. Missing: ${join(", ", [
        for slug in [for actor in var.allow_bypass : split(":", actor)[1] if startswith(actor, "app:")] :
        slug if !contains(keys(var.github_app_ids), slug)
      ])}. Parent module must provide all app IDs in github_app_ids variable."
    }
  }
}

# Deploy keys
resource "github_repository_deploy_key" "deploy_key" {
  for_each   = var.deploy_keys != null ? var.deploy_keys : {}
  title      = each.key
  repository = github_repository.this.name
  key        = each.value.key
  read_only  = lookup(each.value, "read_only", false)
}

# Permissions (teams/users) - using single resource for efficiency
resource "github_repository_collaborators" "all" {
  count      = try(length(local.final_permissions), 0) > 0 ? 1 : 0
  repository = github_repository.this.name

  dynamic "team" {
    for_each = { for k, v in local.final_permissions : k => v if startswith(k, "team:") }
    content {
      team_id    = substr(team.key, 5, length(team.key) - 5)
      permission = team.value
    }
  }

  dynamic "user" {
    for_each = { for k, v in local.final_permissions : k => v if startswith(k, "user:") }
    content {
      username   = substr(user.key, 5, length(user.key) - 5)
      permission = user.value
    }
  }

  lifecycle {
    # Ignore changes to user permissions - GitHub auto-elevates org owners to admin
    # This prevents drift when a user with lower permissions is actually an org owner
    ignore_changes = [user]
  }
}

# Webhooks
resource "github_repository_webhook" "webhook" {
  for_each   = var.webhooks != null ? var.webhooks : {}
  repository = github_repository.this.name
  events     = each.value.events
  configuration {
    url          = each.value.url
    secret       = each.value.secret
    content_type = "json"
    insecure_ssl = false
  }
}

# Repository secrets
resource "github_actions_secret" "repo_secret" {
  for_each = var.repository_secrets != null ? var.repository_secrets : {}

  repository      = github_repository.this.name
  secret_name     = each.key
  plaintext_value = each.value
}

# Repository variables
resource "github_actions_variable" "repo_var" {
  for_each      = var.repository_variables != null ? var.repository_variables : {}
  repository    = github_repository.this.name
  variable_name = each.key
  value         = each.value
}

# Custom properties (metadata)
resource "github_repository_custom_property" "property" {
  for_each       = var.properties != null ? var.properties : {}
  repository     = github_repository.this.name
  property_name  = each.key
  property_type  = "string"
  property_value = [each.value]
}

# workspace custom property (if provided)
resource "github_repository_custom_property" "workspace" {
  count          = var.workspace != null ? 1 : 0
  repository     = github_repository.this.name
  property_name  = "workspace"
  property_type  = "string"
  property_value = [var.workspace]
}

# CI/CD Environments
resource "github_repository_environment" "env" {
  for_each    = var.environments != null ? var.environments : {}
  repository  = github_repository.this.name
  environment = each.key

  dynamic "reviewers" {
    for_each = length([
      for a in lookup(each.value, "required_approvers", []) : a
      if startswith(a, "team:") || startswith(a, "user:")
    ]) > 0 ? [1] : []
    content {
      teams = [
        for a in lookup(each.value, "required_approvers", []) :
        var.github_team_ids[split(":", a)[1]]
        if startswith(a, "team:")
      ]
      users = [
        for a in lookup(each.value, "required_approvers", []) :
        var.github_user_ids[split(":", a)[1]]
        if startswith(a, "user:")
      ]
    }
  }
}

resource "github_actions_environment_secret" "env_secret" {
  for_each = merge([
    for env, v in(var.environments != null ? var.environments : {}) : {
      for k, val in lookup(v, "secrets", {}) : "${env}/${k}" => {
        env   = env
        key   = k
        value = val
      }
    }
  ]...)
  repository      = github_repository.this.name
  environment     = each.value.env
  secret_name     = each.value.key
  plaintext_value = each.value.value
}

resource "github_actions_environment_variable" "env_var" {
  for_each = merge([
    for env, v in(var.environments != null ? var.environments : {}) : {
      for k, val in lookup(v, "variables", {}) : "${env}/${k}" => {
        env   = env
        key   = k
        value = val
      }
    }
  ]...)
  repository    = github_repository.this.name
  environment   = each.value.env
  variable_name = each.value.key
  value         = each.value.value
}

# Branch Protection Ruleset
resource "github_repository_ruleset" "ruleset" {
  count       = length(var.protected_branches) > 0 ? 1 : 0
  repository  = github_repository.this.name
  name        = "protected-branches"
  target      = "branch"
  enforcement = "active"

  # Bypass actors (who can bypass the ruleset rules)
  dynamic "bypass_actors" {
    for_each = local.bypass_actors_final
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = "always"
    }
  }
  conditions {
    ref_name {
      include = [
        for pattern in var.protected_branches :
        startswith(pattern, "refs/heads/") ? pattern : "refs/heads/${pattern}"
      ]
      exclude = []
    }
  }

  rules {
    creation         = false
    update           = false
    deletion         = var.prevent_branch_deletion
    non_fast_forward = var.prevent_force_push

    # Pull request rules
    dynamic "pull_request" {
      for_each = var.required_approvals > 0 ? [1] : []
      content {
        required_approving_review_count   = var.required_approvals
        dismiss_stale_reviews_on_push     = true
        require_code_owner_review         = true
        required_review_thread_resolution = true
      }
    }

    # Status checks rules
    dynamic "required_status_checks" {
      for_each = length(var.required_checks) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = true
        dynamic "required_check" {
          for_each = var.required_checks
          content {
            context        = required_check.value
            integration_id = null
          }
        }
      }
    }
  }
}
