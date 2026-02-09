variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "organization" {
  description = "GitHub organization name"
  type        = string
}

variable "presets" {
  description = "Map of presets for repository configurations"
  type        = map(any)
  default     = {}
}

variable "repository_naming" {
  description = "sprintf-style format string for repository names (e.g., '%s' or 'prefix-%s')"
  type        = string
  default     = "%s"
}

variable "repositories" {
  description = "Map of repositories to create with their configurations"
  type = map(object({
    preset         = optional(string, "default")
    name           = optional(string)
    description    = optional(string)
    visibility     = optional(string)
    default_branch = optional(string)
    topics         = optional(list(string))
    properties     = optional(map(string))
    is_template    = optional(bool)
    template = optional(object({
      repository           = string
      include_all_branches = optional(bool, false)
    }))
    permissions = optional(map(string))
    deploy_keys = optional(map(object({
      key       = string
      read_only = optional(bool, true)
    })))
    allowed_roles = optional(list(string))
    webhooks = optional(map(object({
      url    = string
      events = list(string)
      secret = optional(string)
    })))
    repository_secrets   = optional(map(string))
    repository_variables = optional(map(string))
    environments = optional(map(object({
      required_approvers = optional(list(string), [])
      secrets            = optional(map(string))
      variables          = optional(map(string))
    })))
    protected_branches      = optional(list(string))
    allow_bypass            = optional(list(string))
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

    # Repository-only settings
    archived     = optional(bool)
    homepage_url = optional(string)

    # Security
    vulnerability_alerts        = optional(bool)
    web_commit_signoff_required = optional(bool)
  }))
  default = {}
}

variable "workspace" {
  description = "Optional workspace/namespace for logical grouping of repositories."
  type        = string
  default     = null
}
