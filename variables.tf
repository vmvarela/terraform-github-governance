# ================================================
# Core Configuration
# ================================================

variable "mode" {
  description = <<-EOT
    Governance mode: 'project' or 'organization'.

    - 'organization': Manage entire GitHub organization with full access
    - 'project': Manage a filtered subset with automatic scoping

    Example: mode = "organization"
  EOT
  type        = string
  default     = "project"
  validation {
    condition     = contains(["project", "organization"], var.mode)
    error_message = "Possible values for mode are 'project' or 'organization'."
  }
}

variable "name" {
  description = <<-EOT
    The ID of the project/organization.

    - For organization mode: Your GitHub organization name
    - For project mode: Your project identifier (used with 'spec')

    Example: name = "my-org" or name = "project-x"
  EOT
  type        = string
}

variable "defaults" {
  description = <<-EOT
    Repositories default configuration (if empty).

    Provides fallback values for repository settings when not explicitly set.

    Example:
      defaults = {
        visibility  = "private"
        has_issues  = true
        auto_init   = true
      }
  EOT
  type        = any
  default     = {}
}

# ================================================
# Organization & Repository Settings
# ================================================

variable "settings" {
  description = <<-EOT
    Organization and repository settings (immutable configuration that cannot be overwritten by individual repositories).

    Comprehensive settings object that controls:
    - Organization-level behavior
    - Default repository settings
    - Security defaults for new repositories

    Example:
      settings = {
        description                 = "My organization"
        default_repository_permission = "read"
        web_commit_signoff_required = true
        advanced_security_enabled_for_new_repositories = true
      }
  EOT
  type = object({
    # Organization level settings
    billing_email                                                = optional(string)
    description                                                  = optional(string)
    display_name                                                 = optional(string)
    company                                                      = optional(string)
    blog                                                         = optional(string)
    email                                                        = optional(string)
    location                                                     = optional(string)
    twitter_username                                             = optional(string)
    default_repository_permission                                = optional(string)
    has_organization_projects                                    = optional(bool)
    has_repository_projects                                      = optional(bool)
    members_can_create_repositories                              = optional(bool)
    members_can_create_private_repositories                      = optional(bool)
    members_can_create_public_repositories                       = optional(bool)
    members_can_create_internal_repositories                     = optional(bool)
    members_can_create_pages                                     = optional(bool)
    members_can_create_public_pages                              = optional(bool)
    members_can_create_private_pages                             = optional(bool)
    members_can_fork_private_repositories                        = optional(bool)
    web_commit_signoff_required                                  = optional(bool)
    dependabot_alerts_enabled_for_new_repositories               = optional(bool)
    dependabot_security_updates_enabled_for_new_repositories     = optional(bool)
    dependency_graph_enabled_for_new_repositories                = optional(bool)
    advanced_security_enabled_for_new_repositories               = optional(bool)
    secret_scanning_enabled_for_new_repositories                 = optional(bool)
    secret_scanning_push_protection_enabled_for_new_repositories = optional(bool)

    # Repository level settings (applied to all repositories)
    has_projects                           = optional(bool)
    has_wiki                               = optional(bool)
    has_issues                             = optional(bool)
    has_downloads                          = optional(bool)
    has_discussions                        = optional(bool)
    allow_merge_commit                     = optional(bool)
    allow_squash_merge                     = optional(bool)
    allow_rebase_merge                     = optional(bool)
    allow_auto_merge                       = optional(bool)
    allow_update_branch                    = optional(bool)
    delete_branch_on_merge                 = optional(bool)
    enable_vulnerability_alerts            = optional(bool)
    enable_dependency_graph                = optional(bool)
    enable_advanced_security               = optional(bool)
    enable_secret_scanning                 = optional(bool)
    enable_secret_scanning_push_protection = optional(bool)
    enable_dependabot_security_updates     = optional(bool)
    enable_actions                         = optional(bool)
    is_template                            = optional(bool)
    archived                               = optional(bool)
    archive_on_destroy                     = optional(bool)
    homepage                               = optional(string)
    visibility                             = optional(string)
    template                               = optional(string)
    template_include_all_branches          = optional(bool)
    gitignore_template                     = optional(string)
    license_template                       = optional(string)
    default_branch                         = optional(string)
    auto_init                              = optional(bool)
    actions_access_level                   = optional(string)
    actions_allowed_policy                 = optional(string)
    actions_allowed_github                 = optional(bool)
    actions_allowed_verified               = optional(bool)
    actions_allowed_patterns               = optional(set(string))
    merge_commit_title                     = optional(string)
    merge_commit_message                   = optional(string)
    squash_merge_commit_title              = optional(string)
    squash_merge_commit_message            = optional(string)
    web_commit_signoff_required_repo       = optional(bool)
    pages_source_branch                    = optional(string)
    pages_source_path                      = optional(string)
    pages_build_type                       = optional(string)
    pages_cname                            = optional(string)

    # Nested configurations
    variables = optional(map(string), {})
    users     = optional(map(string), {})
    teams     = optional(map(string), {})
  })
  default = {}

  validation {
    condition = (
      var.settings.billing_email == null ||
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.settings.billing_email))
    )
    error_message = "billing_email must be a valid email address format."
  }

  validation {
    condition = (
      var.settings.email == null ||
      can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.settings.email))
    )
    error_message = "email must be a valid email address format."
  }

  validation {
    condition = try(
      var.settings.default_repository_permission == null ||
      contains(["read", "write", "admin", "none"], var.settings.default_repository_permission),
      true
    )
    error_message = "default_repository_permission must be one of: read, write, admin, none."
  }

  validation {
    condition = try(
      var.settings.visibility == null ||
      contains(["public", "private", "internal"], var.settings.visibility),
      true
    )
    error_message = "visibility must be one of: public, private, internal."
  }

  validation {
    condition = try(
      var.settings.actions_access_level == null ||
      contains(["none", "user", "organization", "enterprise"], var.settings.actions_access_level),
      true
    )
    error_message = "actions_access_level must be one of: none, user, organization, enterprise."
  }

  validation {
    condition = try(
      var.settings.merge_commit_title == null ||
      contains(["PR_TITLE", "MERGE_MESSAGE"], var.settings.merge_commit_title),
      true
    )
    error_message = "merge_commit_title must be one of: PR_TITLE, MERGE_MESSAGE."
  }

  validation {
    condition = try(
      var.settings.merge_commit_message == null ||
      contains(["PR_BODY", "PR_TITLE", "BLANK"], var.settings.merge_commit_message),
      true
    )
    error_message = "merge_commit_message must be one of: PR_BODY, PR_TITLE, BLANK."
  }

  validation {
    condition = try(
      var.settings.squash_merge_commit_title == null ||
      contains(["PR_TITLE", "COMMIT_OR_PR_TITLE"], var.settings.squash_merge_commit_title),
      true
    )
    error_message = "squash_merge_commit_title must be one of: PR_TITLE, COMMIT_OR_PR_TITLE."
  }

  validation {
    condition = try(
      var.settings.squash_merge_commit_message == null ||
      contains(["PR_BODY", "COMMIT_MESSAGES", "BLANK"], var.settings.squash_merge_commit_message),
      true
    )
    error_message = "squash_merge_commit_message must be one of: PR_BODY, COMMIT_MESSAGES, BLANK."
  }
}

# se incluye en todos los repositorios, en modo organization es un role_assigment de organization
variable "teams" {
  description = "The list of collaborators (teams) of all repositories, and their role"
  type        = map(string)
  default     = {}
}

# se incluye en todos los repositorios (se crea un team por role para reducir recursos)
# hay un team basico con el nombre del proyecto y permiso 'read' y por cada role adicional se crea por debajo
# devops --> role-devops-write, role-devops-admin
# en modo organization es un role_assigment de organization
variable "users" {
  description = "The list of collaborators (users) of all repositories, and their role"
  type        = map(string)
  default     = {}
}

# ================================================
# Repository Management
# ================================================

variable "repositories" {
  description = <<-EOT
    Repository configurations map.

    Map of repository names to their configuration objects. Each repository
    can customize settings like visibility, features, security, and more.

    Example:
      repositories = {
        "backend-api" = {
          description = "Backend API service"
          visibility  = "private"
          has_issues  = true
          topics      = ["api", "backend"]
        }
        "frontend-app" = {
          description = "Frontend application"
          visibility  = "public"
          has_discussions = true
        }
      }
  EOT
  type = map(object({
    alias                                  = optional(string)
    description                            = optional(string)
    homepage                               = optional(string)
    visibility                             = optional(string)
    has_issues                             = optional(bool)
    has_projects                           = optional(bool)
    has_wiki                               = optional(bool)
    has_downloads                          = optional(bool)
    has_discussions                        = optional(bool)
    allow_merge_commit                     = optional(bool)
    allow_squash_merge                     = optional(bool)
    allow_rebase_merge                     = optional(bool)
    allow_auto_merge                       = optional(bool)
    allow_update_branch                    = optional(bool)
    delete_branch_on_merge                 = optional(bool)
    enable_vulnerability_alerts            = optional(bool)
    enable_dependency_graph                = optional(bool)
    enable_advanced_security               = optional(bool)
    enable_secret_scanning                 = optional(bool)
    enable_secret_scanning_push_protection = optional(bool)
    enable_dependabot_security_updates     = optional(bool)
    enable_actions                         = optional(bool)
    archived                               = optional(bool)
    archive_on_destroy                     = optional(bool)
    is_template                            = optional(bool)
    template                               = optional(string)
    template_include_all_branches          = optional(bool)
    gitignore_template                     = optional(string)
    license_template                       = optional(string)
    default_branch                         = optional(string)
    auto_init                              = optional(bool)
    topics                                 = optional(list(string))
    actions_access_level                   = optional(string)
    actions_allowed_policy                 = optional(string)
    actions_allowed_github                 = optional(bool, true)
    actions_allowed_verified               = optional(bool)
    actions_allowed_patterns               = optional(set(string))
    merge_commit_title                     = optional(string)
    merge_commit_message                   = optional(string)
    squash_merge_commit_title              = optional(string)
    squash_merge_commit_message            = optional(string)
    web_commit_signoff_required            = optional(bool)
    pages_source_branch                    = optional(string)
    pages_source_path                      = optional(string)
    pages_build_type                       = optional(string)
    pages_cname                            = optional(string)

    # Nested configurations
    teams                        = optional(map(string))
    users                        = optional(map(string))
    variables                    = optional(map(string))
    secrets                      = optional(map(string))
    secrets_encrypted            = optional(map(string))
    dependabot_secrets           = optional(map(string))
    dependabot_secrets_encrypted = optional(map(string))
    dependabot_copy_secrets      = optional(bool)

    # Advanced configurations
    autolink_references = optional(map(object({
      key_prefix      = string
      target_url      = string
      is_alphanumeric = optional(bool, true)
    })))
    branches = optional(map(object({
      source_branch = optional(string)
      source_sha    = optional(string)
    })))
    deploy_keys = optional(map(object({
      public_key = optional(string)
      read_only  = optional(bool, true)
    })))
    deploy_keys_path = optional(string)
    environments = optional(map(object({
      wait_timer          = optional(number)
      can_admins_bypass   = optional(bool, true)
      prevent_self_review = optional(bool, false)
      reviewers_teams     = optional(list(number))
      reviewers_users     = optional(list(number))
      deployment_branch_policy = optional(object({
        protected_branches     = bool
        custom_branch_policies = bool
      }))
    })))
    files = optional(list(object({
      file                = string
      content             = optional(string)
      from_file           = optional(string)
      branch              = optional(string)
      commit_author       = optional(string)
      commit_email        = optional(string)
      commit_message      = optional(string)
      overwrite_on_create = optional(bool, true)
    })), [])
    issue_labels        = optional(map(string))
    issue_labels_colors = optional(map(string))
    rulesets = optional(map(object({
      enforcement = optional(string, "active") # "disabled", "active", "evaluate"
      target      = optional(string, "branch") # "branch", "tag"

      conditions = optional(object({
        ref_name = object({
          include = list(string)
          exclude = list(string)
        })
      }))

      bypass_actors = optional(object({
        repository_roles = optional(list(object({
          repository_role_id = string
          bypass_mode        = optional(string, "always") # "always", "pull_request"
        })), [])
        teams = optional(list(object({
          team_id     = number
          bypass_mode = optional(string, "always")
        })), [])
        integrations = optional(list(object({
          installation_id = number
          bypass_mode     = optional(string, "always")
        })), [])
      }), {})

      rules = optional(object({
        creation                = optional(bool)
        update                  = optional(bool)
        deletion                = optional(bool)
        required_linear_history = optional(bool)
        required_signatures     = optional(bool)

        pull_request = optional(object({
          required_approving_review_count   = optional(number)
          dismiss_stale_reviews_on_push     = optional(bool)
          require_code_owner_review         = optional(bool)
          require_last_push_approval        = optional(bool)
          required_review_thread_resolution = optional(bool)
        }))

        required_status_checks = optional(object({
          strict_required_status_checks_policy = optional(bool)
          required_status_checks = list(object({
            context        = string
            integration_id = optional(number)
          }))
        }))

        non_fast_forward = optional(bool)
      }), {})
    })), {})
    webhooks = optional(map(object({
      url          = string
      content_type = string
      events       = list(string)
      active       = optional(bool, true)
      insecure_ssl = optional(bool, false)
      secret       = optional(string)
    })))
    custom_properties       = optional(map(string))
    custom_properties_types = optional(map(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, repo in var.repositories :
      try(repo.visibility == null || contains(["public", "private", "internal"], repo.visibility), true)
    ])
    error_message = "Repository visibility must be one of: public, private, internal."
  }

  validation {
    condition = alltrue([
      for name, repo in var.repositories :
      try(repo.actions_access_level == null || contains(["none", "user", "organization", "enterprise"], repo.actions_access_level), true)
    ])
    error_message = "Repository actions_access_level must be one of: none, user, organization, enterprise."
  }
}

variable "info_organization" {
  description = "Info about the organization. If not provided, they will be fetched by the module."
  type        = any
  default     = null
}

variable "info_repositories" {
  description = "All repositories in the organization. If not provided, they will be fetched by the module."
  type        = any
  default     = null
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = null
}

variable "spec" {
  description = "Format specification for repository names (i.e \"prefix-%s\")"
  type        = string
  default     = null
  validation {
    condition     = var.mode == "project" ? var.spec != "%s" : true
    error_message = "In project mode, spec cannot be '%s'."
  }
}

variable "variables" {
  description = "Organization/Project common variables to set"
  type        = map(string)
  default     = null
}

variable "secrets" {
  description = <<-EOT
    ⚠️  DEPRECATED: Organization/Project common plaintext secrets to set.

    WARNING: Plaintext secrets are stored unencrypted in Terraform state files, which is a security risk.

    Use secrets_encrypted instead and encrypt secrets with:
      gh secret set SECRET_NAME --body "secret_value"

    Or use external secret management:
      - HashiCorp Vault
      - AWS Secrets Manager
      - Azure Key Vault
      - Google Secret Manager
  EOT
  type        = map(string)
  default     = null

  validation {
    condition     = try(var.secrets == null || length(var.secrets) == 0, true)
    error_message = <<-EOT
      [TF-GH-006] ❌ Plaintext secrets are deprecated and disabled for security reasons.

      Secrets found: ${try(join(", ", keys(var.secrets)), "none")}

      Solutions:
        1. Use secrets_encrypted variable instead
        2. Encrypt with GitHub CLI: gh secret set SECRET_NAME --body "value"
        3. Use external secret management (Vault, AWS SM, Azure KV, Google SM)

      Terraform state files are not encrypted by default. Storing plaintext secrets
      in state exposes them to anyone with access to the state file.

      Documentation: https://docs.github.com/en/actions/security-guides/encrypted-secrets
    EOT
  }
}

# ================================================
# Secrets & Variables
# ================================================

variable "secrets_encrypted" {
  description = <<-EOT
    Organization/Project common encrypted secrets to set.

    Secrets must be encrypted with the organization's public key.
    Use GitHub CLI to encrypt:
      gh secret set SECRET_NAME --body "secret-value"

    Example:
      secrets_encrypted = {
        "DEPLOY_TOKEN" = "base64_encrypted_value"
        "API_KEY"      = "base64_encrypted_value"
      }
  EOT
  type        = map(string)
  default     = null
}

variable "dependabot_secrets" {
  description = <<-EOT
    ⚠️  DEPRECATED: Organization/Project common Dependabot plaintext secrets to set.

    WARNING: Plaintext secrets are stored unencrypted in Terraform state files.
    Use dependabot_secrets_encrypted instead.
  EOT
  type        = map(string)
  default     = null

  validation {
    condition     = try(var.dependabot_secrets == null || length(var.dependabot_secrets) == 0, true)
    error_message = <<-EOT
      [TF-GH-007] ❌ Plaintext Dependabot secrets are deprecated and disabled for security reasons.

      Use dependabot_secrets_encrypted variable instead and encrypt with GitHub CLI:
        gh secret set SECRET_NAME --app dependabot --body "value"

      Documentation: https://docs.github.com/en/code-security/dependabot/working-with-dependabot/configuring-access-to-private-registries-for-dependabot
    EOT
  }
}

variable "dependabot_secrets_encrypted" {
  description = <<-EOT
    Organization/Project common Dependabot encrypted secrets to set.

    Use GitHub CLI to encrypt:
      gh secret set SECRET_NAME --app dependabot --body "value"

    Example:
      dependabot_secrets_encrypted = {
        "NPM_TOKEN" = "base64_encrypted_value"
      }
  EOT
  type        = map(string)
  default     = null
}

variable "dependabot_copy_secrets" {
  description = <<-EOT
    Copy secrets from organization to repositories for Dependabot.

    When true, organization secrets are automatically copied to all repositories
    for use by Dependabot.

    Example: dependabot_copy_secrets = true
  EOT
  type        = bool
  default     = false
}

# ================================================
# Governance & Compliance
# ================================================

variable "rulesets" {
  description = <<-EOT
    Organization/Project rulesets for branch protection and governance.

    ⚠️ REQUIRES: GitHub Team or higher plan

    Define rules that apply across repositories to enforce consistent workflows,
    branch protection, and code quality standards.

    Example:
      rulesets = {
        "protect-main" = {
          enforcement = "active"
          rules = {
            pull_request = {
              required_approving_review_count = 1
            }
            deletion         = true
            non_fast_forward = true
          }
        }
      }
  EOT
  type = map(object({
    enforcement = optional(string, "active")
    rules = optional(object({
      branch_name_pattern = optional(object({
        operator = optional(string)
        pattern  = optional(string)
        name     = optional(string)
        negate   = optional(bool)
      }))
      commit_author_email_pattern = optional(object({
        operator = optional(string)
        pattern  = optional(string)
        name     = optional(string)
        negate   = optional(bool)
      }))
      commit_message_pattern = optional(object({
        operator = optional(string)
        pattern  = optional(string)
        name     = optional(string)
        negate   = optional(bool)
      }))
      committer_email_pattern = optional(object({
        operator = optional(string)
        pattern  = optional(string)
        name     = optional(string)
        negate   = optional(bool)
      }))
      creation         = optional(bool)
      deletion         = optional(bool)
      non_fast_forward = optional(bool)
      pull_request = optional(object({
        dismiss_stale_reviews_on_push     = optional(bool)
        require_code_owner_review         = optional(bool)
        require_last_push_approval        = optional(bool)
        required_approving_review_count   = optional(number)
        required_review_thread_resolution = optional(bool)
      }))
      required_workflows = optional(list(object({
        repository = string
        path       = string
        ref        = optional(string)
      })))
      required_linear_history              = optional(bool)
      required_signatures                  = optional(bool)
      required_status_checks               = optional(map(string))
      strict_required_status_checks_policy = optional(bool)
      tag_name_pattern = optional(object({
        operator = optional(string)
        pattern  = optional(string)
        name     = optional(string)
        negate   = optional(bool)
      }))
      update = optional(bool)
    }))
    target = optional(string, "branch")
    bypass_actors = optional(map(object({
      actor_type  = string
      bypass_mode = string
    })))
    include      = optional(list(string), [])
    exclude      = optional(list(string), [])
    repositories = optional(list(string))
  }))
  default = {}
  validation {
    condition     = alltrue([for name, config in(var.rulesets == null ? {} : var.rulesets) : contains(["active", "evaluate", "disabled"], config.enforcement)])
    error_message = "Possible values for enforcement are active, evaluate or disabled."
  }
  validation {
    condition     = alltrue([for name, config in(var.rulesets == null ? {} : var.rulesets) : contains(["tag", "branch"], config.target)])
    error_message = "Possible values for ruleset target are tag or branch"
  }
}

variable "runner_groups" {
  description = <<-EOT
    Runner groups for GitHub Actions self-hosted runners (key: runner_group_name).

    Behavior by mode:
    - PROJECT MODE: Runner groups automatically include ALL repositories managed by this module.
                    The 'repositories' field is IGNORED and 'visibility' is forced to 'selected'.

    - ORGANIZATION MODE: Runner groups can reference ANY repository in the organization.
                        The 'repositories' field accepts repository names or numeric IDs.
                        Use 'visibility' to control access (all/private/selected).

    Example (organization mode):
      runner_groups = {
        "production" = {
          visibility   = "selected"
          repositories = ["backend-api", "frontend-app"]  # Repository names
        }
      }

    Example (project mode):
      runner_groups = {
        "ci-runners" = {}  # Automatically uses all project repositories
      }
  EOT
  type = map(object({
    visibility                = optional(string, "all")
    workflows                 = optional(set(string))
    repositories              = optional(set(string), [])
    allow_public_repositories = optional(bool)
  }))
  default = {}
  validation {
    condition     = var.runner_groups == null || length(var.runner_groups) == 0 || alltrue([for rg, config in(var.runner_groups == null ? {} : var.runner_groups) : contains(["all", "private", "selected"], config.visibility)])
    error_message = "Possible values for visibility are `all`, `private` or `selected`."
  }
}

# ================================================
# GitHub Actions & CI/CD
# ================================================

variable "repository_roles" {
  description = <<-EOT
    Custom repository roles for the organization (key: role_name).

    ⚠️ REQUIRES: GitHub Enterprise plan

    Create custom roles that extend base permissions with specific capabilities.

    Example:
      repository_roles = {
        "deployer" = {
          description = "Can deploy to production"
          base_role   = "write"
          permissions = ["read", "write", "create_deployment"]
        }
      }
  EOT
  type = map(object({
    description = optional(string)
    base_role   = string
    permissions = set(string)
  }))
  default = {}
  validation {
    condition     = alltrue([for role, config in(var.repository_roles == null ? {} : var.repository_roles) : contains(["read", "triage", "write", "maintain"], config.base_role)])
    error_message = "Possible values for base_role are read, triage, write or maintain."
  }
}

variable "webhooks" {
  description = <<-EOT
    Organization webhooks configuration (key: webhook_name).

    ⚠️ REQUIRES: GitHub Team or higher plan

    Organization webhooks notify external services about events across all repositories.
    For Free plans, use repository-level webhooks instead.

    Example:
      webhooks = {
        "ci-notifications" = {
          url          = "https://ci.example.com/webhook"
          content_type = "json"
          events       = ["push", "pull_request"]
        }
        "security-alerts" = {
          url          = "https://security.example.com/webhook"
          content_type = "json"
          secret       = "webhook_secret"
          events       = ["code_scanning_alert", "dependabot_alert"]
        }
      }
  EOT
  type = map(object({
    active       = optional(bool, true)
    url          = string
    content_type = string
    insecure_ssl = optional(bool, false)
    secret       = optional(string, null)
    events       = list(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for webhook, config in(coalesce(var.webhooks, {})) : contains(["form", "json"], config.content_type)])
    error_message = "Possible values for content_type are 'form' or 'json'."
  }

  validation {
    condition = alltrue([
      for name, webhook in coalesce(var.webhooks, {}) :
      can(regex("^https?://", webhook.url))
    ])
    error_message = "Webhook URLs must start with http:// or https://."
  }

  validation {
    condition = alltrue([
      for name, webhook in coalesce(var.webhooks, {}) :
      length(webhook.events) > 0
    ])
    error_message = "Webhooks must have at least one event configured."
  }

  validation {
    condition = alltrue([
      for name, webhook in coalesce(var.webhooks, {}) :
      webhook.insecure_ssl == true || webhook.secret != null || !can(regex("^https://", webhook.url))
    ])
    error_message = "SECURITY: Webhooks using HTTPS with insecure_ssl=false should have a secret configured to verify payload authenticity."
  }

  validation {
    condition = alltrue([
      for name, webhook in coalesce(var.webhooks, {}) :
      !can(regex("^http://", webhook.url)) || webhook.insecure_ssl == true
    ])
    error_message = "SECURITY WARNING: HTTP webhooks (non-HTTPS) detected. Consider using HTTPS for secure communication."
  }
}
