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
  description = "Optional presets override forwarded to the governance module."
  type        = map(any)
  default     = { "default" = { visibility = "public" } }
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
  default = {}
}

variable "workspace" {
  description = "workspace/namespace for logical grouping of repositories"
  type        = string
}
