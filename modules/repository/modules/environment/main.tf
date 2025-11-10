terraform {
  required_version = ">= 1.6"

  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.6.0"
    }
  }
}

# repository_environment
resource "github_repository_environment" "this" {
  repository          = var.repository
  environment         = var.environment
  wait_timer          = var.wait_timer
  can_admins_bypass   = var.can_admins_bypass
  prevent_self_review = var.prevent_self_review
  dynamic "reviewers" {
    for_each = (var.reviewers_teams != null || var.reviewers_users != null) ? [1] : []
    content {
      teams = var.reviewers_teams
      users = var.reviewers_users
    }
  }
  dynamic "deployment_branch_policy" {
    for_each = (var.protected_branches != null || var.custom_branch_policies != null) ? [1] : []
    content {
      protected_branches     = var.custom_branch_policies == null ? var.protected_branches : false
      custom_branch_policies = try(length(var.custom_branch_policies), 0) > 0
    }
  }
}

# repository_environment_deployment_policy
resource "github_repository_environment_deployment_policy" "this" {
  for_each       = var.custom_branch_policies == null ? [] : var.custom_branch_policies
  repository     = var.repository
  environment    = github_repository_environment.this.environment
  branch_pattern = each.value
}

# actions_environment_secret (plaintext)
resource "github_actions_environment_secret" "plaintext" {
  for_each        = var.secrets == null ? {} : var.secrets
  repository      = var.repository
  environment     = github_repository_environment.this.environment
  secret_name     = each.key
  plaintext_value = each.value
}

# actions_environment_secret (encrypted)
resource "github_actions_environment_secret" "encrypted" {
  for_each        = var.secrets_encrypted == null ? {} : var.secrets_encrypted
  repository      = var.repository
  environment     = github_repository_environment.this.environment
  secret_name     = each.key
  encrypted_value = each.value
}

# actions_environment_variable
resource "github_actions_environment_variable" "this" {
  for_each      = var.variables == null ? {} : var.variables
  repository    = var.repository
  environment   = github_repository_environment.this.environment
  variable_name = each.key
  value         = each.value
  depends_on    = [github_repository_environment.this]
}
