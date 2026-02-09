variable "github_app_ids" {
  description = "Optional map of app slug -> app installation ID. If empty, fetches apps individually via data source. Used for branch protection bypass actors."
  type        = map(number)
  default     = {}
  # Example: { "renovate" = 333, "dependabot" = 444 }
}

variable "github_team_ids" {
  description = "Optional map of team slug -> team ID. If empty, fetches all organization teams via data source. Used for branch protection bypass actors and environment reviewers."
  type        = map(number)
  default     = {}
  # Example: { "sre" = 12345, "platform" = 67890 }
}

variable "github_user_ids" {
  description = "Optional map of user login -> numeric user ID. If empty, repository module resolves IDs individually via data source (less efficient). Used for environment reviewers. Cannot be auto-fetched org-wide as GitHub API returns node IDs (strings) not numeric IDs."
  type        = map(number)
  default     = {}
  # Example: { "alice" = 111, "bob" = 222 }
}

variable "organization" {
  description = "GitHub organization name where repositories will be created."
  type        = string
}

variable "presets" {
  description = "Preset configurations map. Select with repositories[*].preset; falls back to 'default'."
  type = map(object({
    description             = optional(string)
    visibility              = optional(string)
    default_branch          = optional(string)
    topics                  = optional(list(string), [])
    properties              = optional(map(string), {})
    protected_branches      = optional(list(string))
    allow_bypass            = optional(list(string), [])
    required_approvals      = optional(number)
    required_checks         = optional(list(string))
    prevent_force_push      = optional(bool)
    prevent_branch_deletion = optional(bool)

    # Merge settings
    allow_merge_commit          = optional(bool)
    allow_squash_merge          = optional(bool)
    allow_rebase_merge          = optional(bool)
    allow_auto_merge            = optional(bool)
    delete_branch_on_merge      = optional(bool)
    allow_update_branch         = optional(bool)
    squash_merge_commit_title   = optional(string)
    squash_merge_commit_message = optional(string)
    merge_commit_title          = optional(string)
    merge_commit_message        = optional(string)

    # Feature toggles
    has_issues      = optional(bool)
    has_wiki        = optional(bool)
    has_projects    = optional(bool)
    has_discussions = optional(bool)

    # Security
    vulnerability_alerts        = optional(bool)
    web_commit_signoff_required = optional(bool)
  }))
  default = {
    default = {}
  }
}

variable "repository_naming" {
  description = "sprintf-style format string for repository names. Use a single '%s' placeholder for the repository key. Example: '%s' (no prefix), 'myorg-%s' (with prefix)."
  type        = string
  default     = "%s"

  validation {
    condition     = can(regex("^[^%]*%s[^%]*$", var.repository_naming))
    error_message = "repository_naming must contain exactly one '%s' placeholder for the repository key."
  }
}

variable "repositories" {
  description = "Map of repositories to create. The map key is a stable identifier (won't trigger recreation). Use 'name' field to rename repositories safely."
  type = map(object({
    # Optional preset to apply (defaults to "default")
    preset = optional(string, "default")

    # Optional explicit name (allows renaming without Terraform recreation)
    name = optional(string)

    # Core configuration (can override preset)
    description    = optional(string)
    visibility     = optional(string)
    default_branch = optional(string)
    topics         = optional(list(string))
    properties     = optional(map(string))

    # Template
    is_template = optional(bool)
    template = optional(object({
      repository           = string
      include_all_branches = optional(bool, false)
    }))

    # Access & Permissions
    permissions = optional(map(string))
    deploy_keys = optional(map(object({
      key       = string
      read_only = optional(bool, false)
    })))
    allowed_roles = optional(list(string))

    # Automation (Global)
    webhooks = optional(map(object({
      url    = string
      events = list(string)
      secret = optional(string)
    })))
    repository_secrets   = optional(map(string))
    repository_variables = optional(map(string))

    # CI/CD Environments
    environments = optional(map(object({
      required_approvers = optional(list(string), [])
      secrets            = optional(map(string))
      variables          = optional(map(string))
    })))

    # Branch Protection (flattened overrides)
    protected_branches      = optional(list(string))
    allow_bypass            = optional(list(string))
    required_approvals      = optional(number)
    required_checks         = optional(list(string))
    prevent_force_push      = optional(bool)
    prevent_branch_deletion = optional(bool)

    # Merge settings (can override preset)
    allow_merge_commit          = optional(bool)
    allow_squash_merge          = optional(bool)
    allow_rebase_merge          = optional(bool)
    allow_auto_merge            = optional(bool)
    delete_branch_on_merge      = optional(bool)
    allow_update_branch         = optional(bool)
    squash_merge_commit_title   = optional(string)
    squash_merge_commit_message = optional(string)
    merge_commit_title          = optional(string)
    merge_commit_message        = optional(string)

    # Feature toggles (can override preset)
    has_issues      = optional(bool)
    has_wiki        = optional(bool)
    has_projects    = optional(bool)
    has_discussions = optional(bool)

    # Repository-only settings (not in presets)
    archived     = optional(bool)
    homepage_url = optional(string)

    # Security (can override preset)
    vulnerability_alerts        = optional(bool)
    web_commit_signoff_required = optional(bool)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.repositories :
      can(regex("^[a-z0-9_-]+$", k))
    ])
    error_message = "Repository map keys must contain only lowercase letters, numbers, underscores, and hyphens."
  }

  validation {
    condition = alltrue([
      for k, v in var.repositories : contains(keys(var.presets), try(v.preset, "default"))
    ])
    error_message = "Each repository preset must exist as a key in var.presets (missing or invalid preset)."
  }
}

variable "workspace" {
  description = "Optional workspace/namespace name for logical grouping of repositories. If provided, will be stored as a custom property on each repository."
  type        = string
  default     = null
}
