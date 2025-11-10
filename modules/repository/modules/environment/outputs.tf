# ========================================================================
# LEGACY OUTPUTS (Maintained for backwards compatibility)
# ========================================================================

output "environment" {
  description = "Complete environment object (use specific outputs for better terraform graph performance)"
  value       = github_repository_environment.this
}

output "deployment_policies" {
  description = "Created deployment policies"
  value       = github_repository_environment_deployment_policy.this
}

output "secrets_plaintext" {
  description = "Created plaintext secrets"
  value       = github_actions_environment_secret.plaintext
}

output "secrets_encrypted" {
  description = "Created encrypted secrets"
  value       = github_actions_environment_secret.encrypted
}

output "variables" {
  description = "Created variables"
  value       = github_actions_environment_variable.this
}

# ========================================================================
# ENVIRONMENT BASIC OUTPUTS
# ========================================================================

output "id" {
  description = "Numeric ID of the environment"
  value       = github_repository_environment.this.id
}

output "name" {
  description = "Name of the environment"
  value       = github_repository_environment.this.environment
}

output "wait_timer" {
  description = "Wait timer in minutes before deployment"
  value       = github_repository_environment.this.wait_timer
}

output "can_admins_bypass" {
  description = "Whether admins can bypass protection rules"
  value       = github_repository_environment.this.can_admins_bypass
}

output "prevent_self_review" {
  description = "Whether to prevent self-review"
  value       = github_repository_environment.this.prevent_self_review
}

# ========================================================================
# REVIEWERS OUTPUTS
# ========================================================================

output "reviewers" {
  description = "Required reviewers configuration"
  value = {
    teams = try(github_repository_environment.this.reviewers[0].teams, [])
    users = try(github_repository_environment.this.reviewers[0].users, [])
  }
}

# ========================================================================
# DEPLOYMENT POLICY OUTPUTS
# ========================================================================

output "deployment_branch_policy" {
  description = "Deployment branch policy configuration"
  value = {
    protected_branches     = try(github_repository_environment.this.deployment_branch_policy[0].protected_branches, false)
    custom_branch_policies = try(github_repository_environment.this.deployment_branch_policy[0].custom_branch_policies, false)
  }
}

output "custom_deployment_policies_count" {
  description = "Number of custom deployment policies configured"
  value       = length(github_repository_environment_deployment_policy.this)
}

# ========================================================================
# SECRETS AND VARIABLES SUMMARY
# ========================================================================

output "secrets_summary" {
  description = "Summary of secrets configured in this environment"
  value = {
    plaintext_count = length(github_actions_environment_secret.plaintext)
    encrypted_count = length(github_actions_environment_secret.encrypted)
    total_count     = length(github_actions_environment_secret.plaintext) + length(github_actions_environment_secret.encrypted)
  }
}

output "variables_count" {
  description = "Number of variables configured in this environment"
  value       = length(github_actions_environment_variable.this)
}
