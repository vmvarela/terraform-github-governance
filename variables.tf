# ================================================
# Core Configuration
# ================================================

# ================================================
# Repository Presets
# ================================================

variable "repository_presets" {
  description = <<-EOT
    Predefined repository configurations for common use cases.

    Using presets reduces configuration from 20+ lines to just 3 lines per repository.
    Presets include sensible defaults for security, merge settings, and branch protection.

    Available presets:

    - **secure-service**: Backend services, microservices, APIs
      - Private visibility
      - Branch protection (1 approval required)
      - Secret scanning + push protection
      - Dependabot security updates
      - Squash merge only
      - Delete branch on merge

    - **public-library**: Open source libraries, npm/pip packages
      - Public visibility
      - Issues + Discussions + Wiki enabled
      - All merge strategies allowed
      - Community issue labels
      - GitHub Pages ready

    - **documentation**: Documentation sites, knowledge bases
      - Public visibility
      - GitHub Pages configured
      - Discussions enabled
      - Squash merge only

    - **infrastructure**: Infrastructure as Code (Terraform, CloudFormation)
      - Private visibility
      - Strict branch protection (2 approvals)
      - Required signatures
      - Code owner review required
      - Last push approval required

    You can also define custom presets by adding them to this variable.

    Example:
      repository_presets = {
        "my-custom-preset" = {
          description = "My custom configuration"
          visibility  = "private"
          has_issues  = true
          # ... any repository attributes
        }
      }
  EOT
  type = map(object({
    # Basic settings
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
    actions_allowed_github                 = optional(bool)
    actions_allowed_verified               = optional(bool)
    actions_allowed_patterns               = optional(set(string))
    workflow_permissions = optional(object({
      default_workflow_permissions = optional(string, "read")
      can_approve_pull_requests    = optional(bool, false)
    }))
    merge_commit_title          = optional(string)
    merge_commit_message        = optional(string)
    squash_merge_commit_title   = optional(string)
    squash_merge_commit_message = optional(string)
    web_commit_signoff_required = optional(bool)
    pages_source_branch         = optional(string)
    pages_source_path           = optional(string)
    pages_build_type            = optional(string)
    pages_cname                 = optional(string)

    # Advanced configurations
    issue_labels        = optional(map(string))
    issue_labels_colors = optional(map(string))
    rulesets = optional(map(object({
      enforcement = optional(string, "active")
      target      = optional(string, "branch")
      conditions = optional(object({
        ref_name = object({
          include = list(string)
          exclude = list(string)
        })
      }))
      bypass_actors = optional(object({
        repository_roles = optional(list(object({
          repository_role_id = string
          bypass_mode        = optional(string, "always")
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
  }))
  default = {
    # ══════════════════════════════════════════════════════════════
    # Preset: secure-service
    # Perfect for: Backend services, microservices, APIs
    # ══════════════════════════════════════════════════════════════
    "secure-service" = {
      visibility                             = "private"
      has_issues                             = true
      has_projects                           = false
      has_wiki                               = false
      has_discussions                        = false
      allow_merge_commit                     = false
      allow_squash_merge                     = true
      allow_rebase_merge                     = false
      delete_branch_on_merge                 = true
      enable_vulnerability_alerts            = true
      enable_dependency_graph                = true
      enable_dependabot_security_updates     = true
      enable_secret_scanning                 = true
      enable_secret_scanning_push_protection = true
      enable_actions                         = true
      auto_init                              = true

      rulesets = {
        "protect-main" = {
          enforcement = "active"
          target      = "branch"
          conditions = {
            ref_name = {
              include = ["~DEFAULT_BRANCH"]
              exclude = []
            }
          }
          rules = {
            deletion         = true
            non_fast_forward = true
            pull_request = {
              required_approving_review_count = 1
              dismiss_stale_reviews_on_push   = true
            }
          }
        }
      }
    }

    # ══════════════════════════════════════════════════════════════
    # Preset: public-library
    # Perfect for: Open source libraries, npm/pip packages
    # ══════════════════════════════════════════════════════════════
    "public-library" = {
      visibility                         = "public"
      has_issues                         = true
      has_projects                       = true
      has_wiki                           = true
      has_discussions                    = true
      allow_merge_commit                 = true
      allow_squash_merge                 = true
      allow_rebase_merge                 = true
      delete_branch_on_merge             = false
      enable_vulnerability_alerts        = true
      enable_dependency_graph            = true
      enable_dependabot_security_updates = true
      enable_actions                     = true
      auto_init                          = true

      issue_labels = {
        "bug"              = "Something isn't working"
        "enhancement"      = "New feature or request"
        "documentation"    = "Improvements or additions to documentation"
        "good-first-issue" = "Good for newcomers"
        "help-wanted"      = "Extra attention is needed"
      }

      issue_labels_colors = {
        "bug"              = "d73a4a"
        "enhancement"      = "a2eeef"
        "documentation"    = "0075ca"
        "good-first-issue" = "7057ff"
        "help-wanted"      = "008672"
      }
    }

    # ══════════════════════════════════════════════════════════════
    # Preset: documentation
    # Perfect for: Documentation sites, knowledge bases
    # ══════════════════════════════════════════════════════════════
    "documentation" = {
      visibility             = "public"
      has_issues             = true
      has_projects           = false
      has_wiki               = false
      has_discussions        = true
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      delete_branch_on_merge = true
      enable_actions         = true
      auto_init              = true

      pages_build_type    = "workflow"
      pages_source_branch = "main"
      pages_source_path   = "/"
    }

    # ══════════════════════════════════════════════════════════════
    # Preset: infrastructure
    # Perfect for: Terraform modules, CloudFormation, Ansible
    # ══════════════════════════════════════════════════════════════
    "infrastructure" = {
      visibility                             = "private"
      has_issues                             = true
      has_projects                           = false
      has_wiki                               = false
      has_discussions                        = false
      allow_merge_commit                     = false
      allow_squash_merge                     = true
      allow_rebase_merge                     = false
      delete_branch_on_merge                 = true
      enable_vulnerability_alerts            = true
      enable_dependency_graph                = true
      enable_dependabot_security_updates     = true
      enable_secret_scanning                 = true
      enable_secret_scanning_push_protection = true
      enable_actions                         = true
      auto_init                              = true

      rulesets = {
        "protect-production" = {
          enforcement = "active"
          target      = "branch"
          conditions = {
            ref_name = {
              include = ["~DEFAULT_BRANCH"]
              exclude = []
            }
          }
          rules = {
            deletion                = true
            non_fast_forward        = true
            required_signatures     = true
            required_linear_history = true
            pull_request = {
              required_approving_review_count   = 2
              dismiss_stale_reviews_on_push     = true
              require_code_owner_review         = true
              require_last_push_approval        = true
              required_review_thread_resolution = true
            }
          }
        }
      }
    }
  }
}

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
    workflow_permissions = optional(object({
      default_workflow_permissions = optional(string, "read") # "read" or "write"
      can_approve_pull_requests    = optional(bool, false)
    }))
    merge_commit_title               = optional(string)
    merge_commit_message             = optional(string)
    squash_merge_commit_title        = optional(string)
    squash_merge_commit_message      = optional(string)
    web_commit_signoff_required_repo = optional(bool)
    pages_source_branch              = optional(string)
    pages_source_path                = optional(string)
    pages_build_type                 = optional(string)
    pages_cname                      = optional(string)

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

    NEW: Supports presets for simplified configuration!

    Use the 'preset' attribute to apply predefined configurations:
    - secure-service: Backend services, APIs (private, protected, secure)
    - public-library: Open source libraries (public, community-friendly)
    - documentation: Documentation sites (public, GitHub Pages ready)
    - infrastructure: IaC repositories (private, strict protection)

    Example with preset (simplified):
      repositories = {
        "backend-api" = {
          description = "Backend API service"
          preset      = "secure-service"  # 20+ lines of config in 1 line!
        }
      }

    Example with preset override:
      repositories = {
        "critical-service" = {
          description = "Critical service"
          preset      = "secure-service"

          # Override specific settings from preset
          rulesets = {
            "protect-main" = {
              rules = {
                pull_request = {
                  required_approving_review_count = 3  # Override: need 3 approvals
                }
              }
            }
          }
        }
      }

    Example without preset (manual configuration):
      repositories = {
        "legacy-app" = {
          description = "Legacy application"
          visibility  = "private"
          has_issues  = true
          # ... full manual configuration
        }
      }
  EOT
  type = map(object({
    preset                                 = optional(string) # NEW: Preset name from repository_presets
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
    workflow_permissions = optional(object({
      default_workflow_permissions = optional(string, "read") # "read" or "write"
      can_approve_pull_requests    = optional(bool, false)
    }))
    merge_commit_title          = optional(string)
    merge_commit_message        = optional(string)
    squash_merge_commit_title   = optional(string)
    squash_merge_commit_message = optional(string)
    web_commit_signoff_required = optional(bool)
    pages_source_branch         = optional(string)
    pages_source_path           = optional(string)
    pages_build_type            = optional(string)
    pages_cname                 = optional(string)

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
      try(repo.preset == null || contains(keys(var.repository_presets), repo.preset), true)
    ])
    error_message = <<-EOT
      Invalid preset specified in repositories.

      Available presets: ${join(", ", keys(var.repository_presets))}

      You can also define custom presets in the 'repository_presets' variable.
    EOT
  }

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

variable "security_managers" {
  description = <<-EOT
    Teams designated as security managers for the organization.

    Security managers can manage security alerts and settings for all repositories
    in the organization without requiring full admin access.

    ⚠️ REQUIRES: GitHub Team plan or higher

    Security managers can:
    - Manage security and analysis settings for all repositories
    - View security alerts across the organization
    - Manage Dependabot and code scanning alerts
    - Configure secret scanning settings

    Example:
      security_managers = ["security-team", "appsec-team"]
  EOT
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for team_slug in var.security_managers :
      can(regex("^[a-z0-9][a-z0-9-]*$", team_slug))
    ])
    error_message = "Team slugs must contain only lowercase letters, numbers, and hyphens, and cannot start with a hyphen."
  }
}

variable "custom_properties_schema" {
  description = <<-EOT
    Organization-wide custom properties schema definition.

    Custom properties allow you to add metadata to repositories in your organization.
    These properties can be used for categorization, compliance tracking, and reporting.

    ⚠️ REQUIRES: GitHub Enterprise Cloud

    Property types:
    - string: Free-form text (requires default_value if required=true)
    - single_select: One value from predefined list (cannot have default_value if required=false)

    IMPORTANT RULES:
    - Required string properties MUST have a default_value
    - Optional properties (required=false) CANNOT have a default_value
    - Single_select properties must have allowed_values

    Example:
      custom_properties_schema = {
        "cost_center" = {
          description    = "Cost center for billing allocation"
          value_type     = "single_select"
          required       = true
          allowed_values = ["engineering", "sales", "marketing"]
          default_value  = "engineering"
        }
        "team_owner" = {
          description   = "Team responsible for this repository"
          value_type    = "string"
          required      = true
          default_value = "unassigned" # Required for required string properties
        }
        "compliance_level" = {
          description    = "Required compliance level"
          value_type     = "single_select"
          required       = false
          allowed_values = ["sox", "pci", "hipaa", "none"]
          # No default_value - optional properties cannot have defaults
        }
      }
  EOT
  type = map(object({
    description    = optional(string)
    value_type     = string
    required       = optional(bool, false)
    default_value  = optional(string)
    allowed_values = optional(list(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, prop in var.custom_properties_schema :
      contains(["string", "single_select"], prop.value_type)
    ])
    error_message = "Property value_type must be either 'string' or 'single_select'."
  }

  validation {
    condition = alltrue([
      for name, prop in var.custom_properties_schema :
      prop.value_type != "single_select" || (try(length(prop.allowed_values), 0) > 0)
    ])
    error_message = "Properties of type 'single_select' must have allowed_values defined."
  }

  validation {
    condition = alltrue([
      for name, prop in var.custom_properties_schema :
      prop.default_value == null || try(contains(prop.allowed_values, prop.default_value), true)
    ])
    error_message = "default_value must be one of the allowed_values when both are specified."
  }

  validation {
    condition = alltrue([
      for name, prop in var.custom_properties_schema :
      can(regex("^[a-z_][a-z0-9_]*$", name))
    ])
    error_message = "Property names must start with a letter or underscore and contain only lowercase letters, numbers, and underscores."
  }

  validation {
    condition = alltrue([
      for name, prop in var.custom_properties_schema :
      # Required string properties MUST have a default_value
      prop.value_type != "string" || !try(prop.required, false) || prop.default_value != null
    ])
    error_message = "Required string properties must have a default_value specified."
  }

  validation {
    condition = alltrue([
      for name, prop in var.custom_properties_schema :
      # Optional properties CANNOT have a default_value
      try(prop.required, false) || prop.default_value == null
    ])
    error_message = "Optional properties (required=false) cannot have a default_value."
  }
}

variable "organization_roles" {
  description = <<-EOT
    Custom organization roles definition.

    Organization roles provide fine-grained access control across the entire organization,
    including organization-level settings, repositories, and resources.

    ⚠️ REQUIRES: GitHub Enterprise Cloud

    Base roles (inherits permissions from):
    - read: Basic read access
    - triage: Can manage issues and pull requests
    - write: Can push to repositories
    - maintain: Can manage repositories
    - admin: Full administrative access

    Example:
      organization_roles = {
        "security-admin" = {
          description = "Security administrator with audit access"
          base_role   = "read"
          permissions = [
            "read_audit_logs",
            "read_organization_custom_org_role",
            "read_organization_custom_repo_role"
          ]
        }
        "release-manager" = {
          description = "Can manage releases and deployments"
          base_role   = "write"
          permissions = [
            "read_organization_actions_usage_metrics",
            "write_organization_actions_variables"
          ]
        }
      }

    For available permissions, see:
    https://docs.github.com/en/enterprise-cloud@latest/rest/orgs/organization-roles
  EOT
  type = map(object({
    description = optional(string)
    base_role   = optional(string)
    permissions = list(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, role in var.organization_roles :
      length(role.permissions) > 0
    ])
    error_message = "Organization roles must have at least one permission."
  }

  validation {
    condition = alltrue([
      for name, role in var.organization_roles :
      try(role.base_role, null) == null || contains(["read", "triage", "write", "maintain", "admin"], role.base_role)
    ])
    error_message = "Organization role base_role must be one of: read, triage, write, maintain, admin."
  }
}

variable "organization_role_assignments" {
  description = <<-EOT
    Assign organization roles to users and teams.

    This allows you to grant custom organization roles to specific users and teams
    in your organization. Assignments can reference both custom roles (defined in
    organization_roles) and built-in predefined roles.

    ⚠️ REQUIRES: GitHub Enterprise Cloud (for custom roles)

    Example:
      organization_role_assignments = {
        users = {
          "security-admin" = ["user1", "user2"]
          "release-manager" = ["user3"]
        }
        teams = {
          "security-admin" = ["security-team", "audit-team"]
          "release-manager" = ["devops-team"]
        }
      }

    Note: The role names must match either:
    - Keys defined in var.organization_roles (custom roles)
    - GitHub predefined role IDs (e.g., "8132" for all_repo_read)
  EOT
  type = object({
    users = optional(map(list(string)), {})
    teams = optional(map(list(string)), {})
  })
  default = {
    users = {}
    teams = {}
  }

  validation {
    condition = alltrue([
      for role_name, users in var.organization_role_assignments.users :
      alltrue([for user in users : can(regex("^[a-zA-Z0-9-]+$", user))])
    ])
    error_message = "User logins must contain only alphanumeric characters and hyphens."
  }

  validation {
    condition = alltrue([
      for role_name, teams in var.organization_role_assignments.teams :
      alltrue([for team in teams : can(regex("^[a-z0-9][a-z0-9-]*$", team))])
    ])
    error_message = "Team slugs must contain only lowercase letters, numbers, and hyphens, and cannot start with a hyphen."
  }
}
