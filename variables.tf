variable "mode" {
  description = "Governance mode: 'project' or 'organization'"
  type        = string
  default     = "project"
  validation {
    condition     = contains(["project", "organization"], var.mode)
    error_message = "Possible values for mode are 'project' or 'organization'."
  }
}

variable "name" {
  description = "The ID of the project/organization."
  type        = string
}

variable "defaults" {
  description = "Repositories default configuration (if empty)"
  type        = any
  default     = {}
}

variable "settings" {
  description = "Repositories fixed common configuration (cannot be overwritten)"
  type        = any
  default     = {}
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

variable "repositories" {
  description = "Repositories"
  type        = any
  default     = {}
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
  description = "Organization/Project common plaintext secrets to set"
  type        = map(string)
  default     = null
}

variable "secrets_encrypted" {
  description = "Organization/Project common encrypted secrets to set"
  type        = map(string)
  default     = null
}

variable "dependabot_secrets" {
  description = "Organization/Project common Dependabot plaintext secrets to set"
  type        = map(string)
  default     = null
}

variable "dependabot_secrets_encrypted" {
  description = "Organization/Project common Dependabot encrypted secrets to set"
  type        = map(string)
  default     = null
}

variable "dependabot_copy_secrets" {
  description = "Copy secrets from organization to repositories for Dependabot"
  type        = bool
  default     = false
}

variable "rulesets" {
  description = "Organization/Project rules"
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
  description = "The list of runner groups of the organization/project (key: runner_group_name)"
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

variable "repository_roles" {
  description = "The list of custom roles of the organization (key: role_name)"
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
  description = "The list of webhooks of the organization. NOTE: Organization webhooks require GitHub Team or Enterprise plan. GitHub Free organizations will receive a 404 error. Use repository-level webhooks for Free plans."
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
}
