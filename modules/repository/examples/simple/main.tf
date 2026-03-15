terraform {
  required_version = ">= 1.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.8.0"
    }
  }
}

provider "github" {
  owner = var.organization
  token = var.github_token
}

# Data sources to resolve team/user/app IDs
# Note: In production, the parent governance module handles this
data "github_team" "teams" {
  for_each = toset([
    for actor in var.allow_bypass : split(":", actor)[1]
    if startswith(actor, "team:")
  ])
  slug = each.value
}

data "github_user" "users" {
  for_each = toset(flatten([
    for env in values(var.environments) : [
      for approver in lookup(env, "required_approvers", []) : split(":", approver)[1]
      if startswith(approver, "user:")
    ]
  ]))
  username = each.value
}

locals {
  # Build ID maps from data sources
  github_team_ids = {
    for slug, team in data.github_team.teams : slug => team.id
  }

  github_user_ids = {
    for login, user in data.github_user.users : login => user.id
  }

  github_app_ids = {} # Add apps if needed
}

module "repo" {
  source                  = "../../"
  name                    = var.name
  description             = var.description
  visibility              = var.visibility
  default_branch          = var.default_branch
  organization            = var.organization
  topics                  = var.topics
  properties              = var.properties
  is_template             = var.is_template
  template                = var.template
  permissions             = var.permissions
  deploy_keys             = var.deploy_keys
  allowed_roles           = var.allowed_roles
  webhooks                = var.webhooks
  repository_secrets      = var.repository_secrets
  repository_variables    = var.repository_variables
  environments            = var.environments
  protected_branches      = var.protected_branches
  allow_bypass            = var.allow_bypass
  required_approvals      = var.required_approvals
  required_checks         = var.required_checks
  prevent_force_push      = var.prevent_force_push
  prevent_branch_deletion = var.prevent_branch_deletion

  # Required: IDs must be provided (normally by parent governance module)
  github_team_ids = local.github_team_ids
  github_user_ids = local.github_user_ids
  github_app_ids  = local.github_app_ids
}
