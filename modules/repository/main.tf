terraform {
  required_version = ">= 1.6"

  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.6"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.3"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.2"
    }
  }
}

locals {
  alias = coalesce(var.alias, var.name)

  visibility = (var.visibility == null && var.private != null) ? (var.private ? "private" : "public") : var.visibility

  allowed_scanning                       = (var.visibility == "public" || var.enable_advanced_security == true)
  enable_secret_scanning                 = var.enable_secret_scanning == true && local.allowed_scanning
  enable_secret_scanning_push_protection = var.enable_secret_scanning_push_protection == true && local.allowed_scanning

  custom_properties = var.custom_properties == null ? {} : { for i in [
    for n, a in var.custom_properties : {
      property = n
      type     = try(var.custom_properties_types[n], "string")
      value    = flatten([a])
    }
    ] : i.property => i
  }
}

# actions_repository_access_level
resource "github_actions_repository_access_level" "this" {
  count        = var.actions_access_level != null ? 1 : 0
  repository   = github_repository.this.name
  access_level = var.actions_access_level
}

# actions_repository_permissions
resource "github_actions_repository_permissions" "this" {
  count           = (var.enable_actions != null || var.actions_allowed_policy != null) ? 1 : 0
  repository      = github_repository.this.name
  enabled         = var.enable_actions
  allowed_actions = var.enable_actions == false ? null : var.actions_allowed_policy
  dynamic "allowed_actions_config" {
    for_each = (var.enable_actions == false ? null : var.actions_allowed_policy) == "selected" ? [1] : []
    content {
      github_owned_allowed = var.actions_allowed_github
      patterns_allowed     = var.actions_allowed_patterns
      verified_allowed     = var.actions_allowed_verified
    }
  }
}

# actions_secret (plaintext)
resource "github_actions_secret" "plaintext" {
  for_each        = var.secrets
  repository      = github_repository.this.name
  secret_name     = each.key
  plaintext_value = each.value
}

# actions_secret (encrypted)
resource "github_actions_secret" "encrypted" {
  for_each        = var.secrets_encrypted
  repository      = github_repository.this.name
  secret_name     = each.key
  encrypted_value = each.value
}

# actions_variable
resource "github_actions_variable" "this" {
  for_each      = var.variables
  repository    = github_repository.this.name
  variable_name = each.key
  value         = each.value
}

# branch
resource "github_branch" "this" {
  for_each   = var.branches
  repository = github_repository.this.name
  branch     = each.key
  # If each.value does not start with "sha:", set source_branch to each.value, otherwise set it to null
  source_branch = !try(startswith(each.value, "sha:"), false) ? each.value : null
  source_sha    = try(startswith(each.value, "sha:"), false) ? substr(each.value, 4, length(each.value) - 4) : null
}

# branch_default
resource "github_branch_default" "this" {
  count      = var.default_branch != null ? 1 : 0
  repository = github_repository.this.name
  branch     = var.default_branch
}

# dependabot_secret (plaintext)
resource "github_dependabot_secret" "plaintext" {
  for_each        = var.dependabot_secrets != null ? var.dependabot_secrets : (var.dependabot_copy_secrets ? var.secrets : {})
  repository      = github_repository.this.name
  secret_name     = each.key
  plaintext_value = each.value
}

# dependabot_secret (encrypted)
resource "github_dependabot_secret" "encrypted" {
  for_each        = var.dependabot_secrets_encrypted != null ? var.dependabot_secrets_encrypted : (var.dependabot_copy_secrets ? var.secrets_encrypted : {})
  repository      = github_repository.this.name
  secret_name     = each.key
  encrypted_value = each.value
}

# issue_labels
resource "github_issue_labels" "this" {
  count      = var.issue_labels != null ? 1 : 0
  repository = github_repository.this.name

  dynamic "label" {
    for_each = var.issue_labels
    content {
      name        = label.key
      color       = var.issue_labels_colors == null ? substr(sha256(label.key), 0, 6) : lookup(var.issue_labels_colors, label.key, substr(sha256(label.key), 0, 6))
      description = label.value
    }
  }
}

# repository
resource "github_repository" "this" {
  name                        = var.name
  description                 = var.description
  homepage_url                = var.homepage
  private                     = var.private
  visibility                  = local.visibility
  has_issues                  = var.has_issues
  has_projects                = var.has_projects
  has_wiki                    = var.has_wiki
  is_template                 = var.is_template
  allow_merge_commit          = var.allow_merge_commit
  allow_squash_merge          = var.allow_squash_merge
  allow_rebase_merge          = var.allow_rebase_merge
  allow_auto_merge            = var.allow_auto_merge
  squash_merge_commit_title   = var.squash_merge_commit_title
  squash_merge_commit_message = var.squash_merge_commit_message
  merge_commit_title          = var.merge_commit_title
  merge_commit_message        = var.merge_commit_message
  delete_branch_on_merge      = var.delete_branch_on_merge
  auto_init                   = var.auto_init != null || var.default_branch != null
  gitignore_template          = var.gitignore_template
  license_template            = var.license_template
  archived                    = var.archived
  archive_on_destroy          = var.archive_on_destroy
  topics                      = var.topics
  vulnerability_alerts        = var.enable_vulnerability_alerts
  allow_update_branch         = var.allow_update_branch
  web_commit_signoff_required = var.web_commit_signoff_required

  dynamic "pages" {
    for_each = var.pages_build_type != null ? [1] : []
    content {
      dynamic "source" {
        for_each = var.pages_source_branch != null ? [1] : []
        content {
          branch = var.pages_source_branch
          path   = var.pages_source_path
        }
      }
      build_type = var.pages_build_type
      cname      = var.pages_cname
    }
  }

  dynamic "security_and_analysis" {
    for_each = (var.enable_advanced_security != null || var.enable_secret_scanning != null || var.enable_secret_scanning_push_protection != null) ? [1] : []
    content {
      dynamic "advanced_security" {
        for_each = var.enable_advanced_security ? [1] : []
        content {
          status = var.enable_advanced_security ? "enabled" : "disabled"
        }
      }
      dynamic "secret_scanning" {
        for_each = local.enable_secret_scanning == null ? [] : [1]
        content {
          status = local.enable_secret_scanning ? "enabled" : "disabled"
        }
      }
      dynamic "secret_scanning_push_protection" {
        for_each = local.enable_secret_scanning_push_protection ? [1] : []
        content {
          status = local.enable_secret_scanning_push_protection ? "enabled" : "disabled"
        }
      }
    }
  }

  dynamic "template" {
    for_each = var.template == null ? [] : [1]
    content {
      owner                = try(element(split("/", var.template), 0), null)
      repository           = try(element(split("/", var.template), 1), null)
      include_all_branches = var.template_include_all_branches
    }
  }
}

# repository_autolink_reference
resource "github_repository_autolink_reference" "this" {
  for_each            = var.autolink_references
  repository          = github_repository.this.name
  key_prefix          = each.key
  target_url_template = each.value
}

# repository_collaborators
resource "github_repository_collaborators" "this" {
  count      = (var.teams != null || var.users != null) ? 1 : 0
  repository = github_repository.this.name
  dynamic "user" {
    for_each = var.users
    content {
      permission = user.value
      username   = user.key
    }
  }
  dynamic "team" {
    for_each = var.teams
    content {
      permission = team.value
      team_id    = team.key
    }
  }
}

# repository_custom_property
resource "github_repository_custom_property" "this" {
  for_each       = local.custom_properties
  repository     = github_repository.this.name
  property_name  = each.key
  property_type  = each.value.type
  property_value = each.value.value
}

# repository_dependabot_security_updates
resource "github_repository_dependabot_security_updates" "this" {
  count      = var.enable_dependabot_security_updates != null ? 1 : 0
  repository = github_repository.this.name
  enabled    = var.enable_dependabot_security_updates
}

# repository_deploy_key
resource "github_repository_deploy_key" "this" {
  for_each   = var.deploy_keys
  repository = github_repository.this.name
  title      = each.key
  key        = each.value.public_key != null ? each.value.public_key : tls_private_key.this[each.key].public_key_openssh
  read_only  = each.value.read_only
}

# auto-generated if the public_key is not provided
resource "tls_private_key" "this" {
  for_each  = { for k, v in var.deploy_keys : k => v if v.public_key == null }
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "null_resource" "create_subfolder" {
  count = var.deploy_keys_path == null ? 0 : 1
  provisioner "local-exec" {
    command = "mkdir -p ${var.deploy_keys_path}"
  }
}

resource "local_file" "private_key_file" {
  for_each = var.deploy_keys_path == null ? {} : { for k, v in var.deploy_keys : k => v if v.public_key == null }
  filename = "${var.deploy_keys_path}/${github_repository.this.name}-${each.key}.pem"
  content  = tls_private_key.this[each.key].private_key_openssh
  depends_on = [
    null_resource.create_subfolder
  ]
}

module "environment" {
  for_each               = var.environments
  source                 = "./modules/environment"
  repository             = github_repository.this.name
  environment            = each.key
  wait_timer             = try(each.value.wait_timer, null)
  can_admins_bypass      = try(each.value.can_admins_bypass, null)
  prevent_self_review    = try(each.value.prevent_self_review, null)
  reviewers_teams        = try(each.value.reviewers_teams, null)
  reviewers_users        = try(each.value.reviewers_users, null)
  protected_branches     = try(each.value.protected_branches, null)
  custom_branch_policies = try(each.value.custom_branch_policies, null)
  secrets                = try(each.value.secrets, null)
  secrets_encrypted      = try(each.value.secrets_encrypted, null)
  variables              = try(each.value.variables, null)
}

module "file" {
  for_each       = { for f in var.files : sha1(format("%s:%s", try(f.branch, "_default_"), f.file)) => f }
  source         = "./modules/file"
  repository     = github_repository.this.name
  file           = each.value.file
  content        = try(each.value.content, null)
  from_file      = try(each.value.from_file, null)
  branch         = try(each.value.branch, null)
  commit_author  = try(each.value.commit_author, null)
  commit_email   = try(each.value.commit_email, null)
  commit_message = try(each.value.commit_message, null)
}

module "webhook" {
  for_each     = { for w in var.webhooks : sha1(try(w.url, "_default_")) => w }
  source       = "./modules/webhook"
  repository   = github_repository.this.name
  url          = each.value.url
  events       = try(each.value.events, [])
  content_type = try(each.value.content_type, "form")
  insecure_ssl = try(each.value.insecure_ssl, false)
  secret       = try(each.value.secret, null)
}

module "ruleset" {
  for_each                             = var.rulesets
  source                               = "./modules/ruleset"
  repository                           = github_repository.this.name
  name                                 = each.key
  enforcement                          = try(each.value.enforcement, "active")
  target                               = try(each.value.target, "branch")
  include                              = try(each.value.include, [])
  exclude                              = try(each.value.exclude, [])
  bypass_mode                          = try(each.value.bypass_mode, "always")
  bypass_organization_admin            = try(each.value.bypass_organization_admin, null)
  bypass_roles                         = try(each.value.bypass_roles, [])
  bypass_teams                         = try(each.value.bypass_teams, [])
  bypass_integration                   = try(each.value.bypass_integration, [])
  regex_target                         = try(each.value.regex_target, null)
  regex_commit_author_email            = try(each.value.regex_commit_author_email, null)
  regex_committer_email                = try(each.value.regex_committer_email, null)
  regex_commit_message                 = try(each.value.regex_commit_message, null)
  forbidden_creation                   = try(each.value.forbidden_creation, null)
  forbidden_deletion                   = try(each.value.forbidden_deletion, null)
  forbidden_update                     = try(each.value.forbidden_update, null)
  forbidden_fast_forward               = try(each.value.forbidden_fast_forward, null)
  dismiss_pr_stale_reviews_on_push     = try(each.value.dismiss_pr_stale_reviews_on_push, null)
  required_pr_code_owner_review        = try(each.value.required_pr_code_owner_review, null)
  required_pr_last_push_approval       = try(each.value.required_pr_last_push_approval, null)
  required_pr_approving_review_count   = try(each.value.required_pr_approving_review_count, null)
  required_pr_review_thread_resolution = try(each.value.required_pr_review_thread_resolution, null)
  required_deployment_environments     = try(each.value.required_deployment_environments, [])
  required_linear_history              = try(each.value.required_linear_history, null)
  required_signatures                  = try(each.value.required_signatures, null)
  required_checks                      = try(each.value.required_checks, [])
  required_code_scanning               = try(each.value.required_code_scanning, {})
  depends_on                           = [module.environment]
}
