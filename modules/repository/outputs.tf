# ========================================================================
# LEGACY OUTPUTS (Maintained for backwards compatibility)
# ========================================================================

output "repository" {
  description = "Complete repository object (use specific outputs for better terraform graph performance)"
  value       = github_repository.this
}

output "alias" {
  description = "Repository alias (used for renaming operations)"
  value       = local.alias
}

output "private_keys" {
  description = "Auto-generated private deploy keys (sensitive)"
  value       = tls_private_key.this
  sensitive   = true
}

# ========================================================================
# REPOSITORY BASIC OUTPUTS
# ========================================================================

output "repository_id" {
  description = "Numeric ID of the repository"
  value       = github_repository.this.repo_id
}

output "repository_name" {
  description = "Name of the repository"
  value       = github_repository.this.name
}

output "repository_full_name" {
  description = "Full name of the repository (owner/name)"
  value       = github_repository.this.full_name
}

output "repository_node_id" {
  description = "GraphQL global node ID of the repository"
  value       = github_repository.this.node_id
}

output "repository_url" {
  description = "URL to the repository on GitHub"
  value       = github_repository.this.html_url
}

output "repository_git_clone_url" {
  description = "HTTPS URL to clone the repository"
  value       = github_repository.this.http_clone_url
}

output "repository_ssh_clone_url" {
  description = "SSH URL to clone the repository"
  value       = github_repository.this.ssh_clone_url
}

output "default_branch" {
  description = "Name of the default branch"
  value       = try(github_branch_default.this[0].branch, null)
}

output "visibility" {
  description = "Visibility of the repository (public/private/internal)"
  value       = github_repository.this.visibility
}

output "topics" {
  description = "List of topics associated with the repository"
  value       = github_repository.this.topics
}

output "homepage_url" {
  description = "Homepage URL of the repository"
  value       = github_repository.this.homepage_url
}

output "is_template" {
  description = "Whether the repository is a template"
  value       = github_repository.this.is_template
}

output "archived" {
  description = "Whether the repository is archived"
  value       = github_repository.this.archived
}

# ========================================================================
# SECURITY CONFIGURATION OUTPUTS
# ========================================================================

output "security_configuration" {
  description = "Security features enabled on the repository"
  value = {
    advanced_security_enabled       = try(github_repository.this.security_and_analysis[0].advanced_security[0].status, "disabled") == "enabled"
    secret_scanning_enabled         = try(github_repository.this.security_and_analysis[0].secret_scanning[0].status, "disabled") == "enabled"
    secret_scanning_push_protection = try(github_repository.this.security_and_analysis[0].secret_scanning_push_protection[0].status, "disabled") == "enabled"
    vulnerability_alerts_enabled    = github_repository.this.vulnerability_alerts
    dependabot_security_updates     = try(github_repository_dependabot_security_updates.this[0].enabled, null)
  }
}

# ========================================================================
# MERGE CONFIGURATION OUTPUTS
# ========================================================================

output "merge_configuration" {
  description = "Merge configuration for pull requests"
  value = {
    allow_merge_commit          = github_repository.this.allow_merge_commit
    allow_squash_merge          = github_repository.this.allow_squash_merge
    allow_rebase_merge          = github_repository.this.allow_rebase_merge
    allow_auto_merge            = github_repository.this.allow_auto_merge
    delete_branch_on_merge      = github_repository.this.delete_branch_on_merge
    squash_merge_commit_title   = github_repository.this.squash_merge_commit_title
    squash_merge_commit_message = github_repository.this.squash_merge_commit_message
    merge_commit_title          = github_repository.this.merge_commit_title
    merge_commit_message        = github_repository.this.merge_commit_message
  }
}

# ========================================================================
# FEATURES OUTPUTS
# ========================================================================

output "features_enabled" {
  description = "Repository features status"
  value = {
    issues      = github_repository.this.has_issues
    projects    = github_repository.this.has_projects
    wiki        = github_repository.this.has_wiki
    downloads   = github_repository.this.has_downloads
    discussions = try(github_repository.this.has_discussions, false)
  }
}

# ========================================================================
# SUBMODULES OUTPUTS
# ========================================================================

output "environments" {
  description = "Map of environment names to their configuration"
  value = {
    for env_name, env_module in module.environment :
    env_name => {
      name              = env_module.name
      id                = env_module.id
      wait_timer        = env_module.wait_timer
      can_admins_bypass = env_module.can_admins_bypass
    }
  }
}

output "webhooks" {
  description = "Map of webhook URLs to their configuration"
  value = {
    for webhook_key, webhook_module in module.webhook :
    webhook_key => {
      id     = webhook_module.id
      url    = webhook_module.url
      active = webhook_module.active
    }
  }
}

output "rulesets" {
  description = "Map of ruleset names to their IDs"
  value = {
    for ruleset_name, ruleset_module in module.ruleset :
    ruleset_name => {
      id          = ruleset_module.id
      name        = ruleset_module.name
      enforcement = ruleset_module.enforcement
    }
  }
}

# ========================================================================
# DEPLOY KEYS OUTPUTS
# ========================================================================

output "deploy_keys" {
  description = "Map of deploy key names to their configuration"
  value = {
    for key_name, deploy_key in github_repository_deploy_key.this :
    key_name => {
      id        = deploy_key.id
      title     = deploy_key.title
      read_only = deploy_key.read_only
      # Public key is not exposed for security reasons
    }
  }
}

output "auto_generated_deploy_keys" {
  description = "List of auto-generated deploy key names (private keys available via private_keys output)"
  value       = [for k, v in var.deploy_keys : k if v.public_key == null]
}
