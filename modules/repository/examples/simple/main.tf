terraform {
  required_version = ">= 1.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.8.1"
    }
  }
}

provider "github" {
  owner = var.organization
  token = var.github_token
}

module "repo" {
  source                  = "../../"
  name                    = var.name
  description             = var.description
  visibility              = var.visibility
  default_branch          = var.default_branch
  organization            = var.organization
  workspace               = var.workspace
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
}
