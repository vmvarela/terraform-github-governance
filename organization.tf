# ========================================================================
# ORGANIZATION-EXCLUSIVE RESOURCES
# ========================================================================
# This file contains resources that ONLY work in organization mode.
# These resources are NOT available in project mode.
#
# ALL resources in this file must check: var.mode == "organization"
#
# Resources that work in BOTH modes (like organization_ruleset) belong in main.tf
# ========================================================================

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
    # PROTECTION: Critical organization settings should not be destroyed without review
    prevent_destroy = true

    # IGNORE: Fields that are often modified outside Terraform via GitHub UI
    ignore_changes = [
      name,
      description,
      blog,
      twitter_username,
      location,
    ]
  }
}

# ========================================================================
# ORGANIZATION REPOSITORY ROLES
# ========================================================================

# organization_repository_role
# NOTE: Using deprecated github_organization_custom_role due to provider bug in github_organization_repository_role
# TODO: Migrate to github_organization_repository_role when provider issue is fixed
resource "github_organization_custom_role" "this" {
  for_each    = var.mode == "organization" ? coalesce(var.repository_roles, {}) : {}
  name        = each.key
  description = each.value.description
  base_role   = each.value.base_role
  permissions = each.value.permissions
}

# ========================================================================
# ORGANIZATION WEBHOOKS
# ========================================================================

# organization_webhook
# NOTE: Organization webhooks require GitHub Team or Enterprise plan.
# For GitHub Free organizations, use repository-level webhooks instead.
resource "github_organization_webhook" "this" {
  for_each = var.mode == "organization" ? coalesce(var.webhooks, {}) : {}
  active   = true
  configuration {
    url          = each.value.url
    content_type = each.value.content_type
    insecure_ssl = each.value.insecure_ssl
    secret       = each.value.secret
  }
  events = each.value.events
}

# ========================================================================
# ORGANIZATION SECURITY MANAGERS
# ========================================================================

# organization_security_manager
# NOTE: Requires GitHub Team plan or higher.
# Security managers can manage security alerts and settings for all repositories
# without requiring full admin access to the organization.
resource "github_organization_security_manager" "this" {
  for_each  = var.mode == "organization" ? toset(var.security_managers) : toset([])
  team_slug = each.value

  lifecycle {
    # PROTECTION: Security manager assignments are critical for security governance
    prevent_destroy = true

    # STRATEGY: Allow modifications without recreating
    create_before_destroy = true
  }
}

# ========================================================================
# ORGANIZATION CUSTOM PROPERTIES
# ========================================================================

# organization_custom_properties
# NOTE: Requires GitHub Enterprise Cloud.
# Defines organization-wide custom property schema that can be applied to repositories.
# These properties enable metadata-driven governance and reporting.
# Each property is a separate resource instance.
resource "github_organization_custom_properties" "this" {
  for_each = var.mode == "organization" ? var.custom_properties_schema : {}

  property_name  = each.key
  value_type     = each.value.value_type
  description    = try(each.value.description, null)
  required       = try(each.value.required, false)
  default_value  = try(each.value.default_value, null)
  allowed_values = try(each.value.allowed_values, null)

  lifecycle {
    # PROTECTION: Custom properties schema is critical for governance
    prevent_destroy = true

    # STRATEGY: Allow modifications without recreating
    create_before_destroy = true
  }
}

# ========================================================================
# ORGANIZATION ROLES (Custom Organization-Wide Roles)
# ========================================================================

# organization_role
# NOTE: Requires GitHub Enterprise Cloud.
# Custom organization roles provide fine-grained access control across the entire
# organization, including organization-level settings, repositories, and resources.
# Unlike repository roles, organization roles can grant permissions to organization-wide
# features like audit logs, organization settings, and cross-repository management.
resource "github_organization_role" "this" {
  for_each = var.mode == "organization" ? var.organization_roles : {}

  name        = each.key
  description = try(each.value.description, null)
  base_role   = try(each.value.base_role, null)
  permissions = each.value.permissions

  lifecycle {
    # PROTECTION: Organization roles are critical for access control
    prevent_destroy = true

    # STRATEGY: Allow modifications without recreating
    create_before_destroy = true
  }
}

# Local to map role names to role IDs (for assignments)
# Combines custom roles created by this module with any pre-existing roles
locals {
  # Map of custom role names to their IDs
  organization_role_ids = {
    for name, role in github_organization_role.this :
    name => role.role_id
  }

  # Flatten user assignments: role_name -> list of users
  # Result: [{ role_name = "security-admin", user = "user1" }, ...]
  organization_role_user_assignments = flatten([
    for role_name, users in var.organization_role_assignments.users : [
      for user in users : {
        role_name = role_name
        user      = user
      }
    ]
  ])

  # Flatten team assignments: role_name -> list of teams
  # Result: [{ role_name = "security-admin", team = "security-team" }, ...]
  organization_role_team_assignments = flatten([
    for role_name, teams in var.organization_role_assignments.teams : [
      for team in teams : {
        role_name = role_name
        team      = team
      }
    ]
  ])
}

# organization_role_user
# Assigns an organization role to a user.
# The role can be either a custom role created by this module or a predefined GitHub role.
resource "github_organization_role_user" "this" {
  for_each = var.mode == "organization" ? {
    for assignment in local.organization_role_user_assignments :
    "${assignment.role_name}:${assignment.user}" => assignment
  } : {}

  # Use custom role ID if it exists, otherwise assume it's a predefined role ID
  role_id = try(local.organization_role_ids[each.value.role_name], tonumber(each.value.role_name))
  login   = each.value.user

  # Ensure custom roles are created before assignments
  depends_on = [github_organization_role.this]

  lifecycle {
    # STRATEGY: Allow modifications without recreating
    create_before_destroy = true
  }
}

# organization_role_team
# Assigns an organization role to a team.
# The role can be either a custom role created by this module or a predefined GitHub role.
resource "github_organization_role_team" "this" {
  for_each = var.mode == "organization" ? {
    for assignment in local.organization_role_team_assignments :
    "${assignment.role_name}:${assignment.team}" => assignment
  } : {}

  # Use custom role ID if it exists, otherwise assume it's a predefined role ID
  role_id   = try(local.organization_role_ids[each.value.role_name], tonumber(each.value.role_name))
  team_slug = each.value.team

  # Ensure custom roles are created before assignments
  depends_on = [github_organization_role.this]

  lifecycle {
    # STRATEGY: Allow modifications without recreating
    create_before_destroy = true
  }
}
