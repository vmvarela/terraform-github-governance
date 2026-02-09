# Governance module - orchestrates multiple repositories with shared configuration
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
  permissions = each.value.permissions
  deploy_keys = each.value.deploy_keys

  # Automation (Global)
  webhooks             = each.value.webhooks
  repository_secrets   = each.value.repository_secrets
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

  # Pre-fetched allowed roles (base + custom if detected)
  allowed_roles = local.allowed_roles
}
