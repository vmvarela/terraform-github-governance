variable "github_token" {
  type        = string
  description = "GitHub personal access token"
  sensitive   = true
}

variable "organization" {
  type        = string
  description = "GitHub organization name"
}

variable "workspace" {
  type        = string
  description = "workspace/namespace for logical grouping of repositories"
}

variable "repository_naming" {
  type        = string
  description = "sprintf-style format string for repository names (e.g., '%s' or 'prefix-%s')"
  default     = "%s"
}

variable "repositories" {
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
    repository_secrets = optional(map(object({
      value     = string
      sensitive = optional(bool, true)
    })))
    repository_variables = optional(map(string))
    environments = optional(map(object({
      required_approvers = optional(list(string))
      secrets            = optional(map(string))
      variables          = optional(map(string))
    })))
    protected_branches      = optional(list(string))
    allow_bypass            = optional(list(string))
    required_approvals      = optional(number)
    required_checks         = optional(list(string))
    prevent_force_push      = optional(bool)
    prevent_branch_deletion = optional(bool)
  }))
  description = "Map of repositories to create with their configurations"
  default     = {}
}

variable "presets" {
  description = "Optional presets override forwarded to the governance module."
  type        = map(any)
  default     = { "default" = { visibility = "public" } }
}
