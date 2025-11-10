variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_app_id" {
  description = "GitHub App ID"
  type        = number
  sensitive   = true
  default     = null
}

variable "github_app_private_key" {
  description = "GitHub App private key (PEM format)"
  type        = string
  sensitive   = true
  default     = null
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = number
  sensitive   = true
  default     = null
}

variable "github_token" {
  description = "GitHub Token"
  type        = string
  sensitive   = true
  default     = null
}

variable "github_repositories" {
  description = "All repositories in the organization. If not provided, they will be fetched by the module."
  type        = any
  default     = null
}

variable "controller" {
  description = "Controller configuration"
  type = object({
    name             = optional(string, "arc")
    namespace        = optional(string, "arc-systems")
    create_namespace = optional(bool, true)
    version          = optional(string, "0.13.0")
  })
  default = {
    name             = "arc"
    namespace        = "arc-systems"
    create_namespace = true
    version          = "0.13.0"
  }
  validation {
    condition     = var.controller == null || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.controller.version))
    error_message = "Version format must be <major>.<minor>.<patch> (example: 0.13.0)"
  }
}

variable "scale_sets" {
  description = "Scale sets configuration (map)"
  type = map(object({
    runner_group        = optional(string, null)
    create_runner_group = optional(bool, true)
    namespace           = optional(string, "arc-runners")
    create_namespace    = optional(bool, true)
    version             = optional(string, "0.13.0")
    min_runners         = optional(number, 1)
    max_runners         = optional(number, 5)
    runner_image        = optional(string, "ghcr.io/actions/actions-runner:latest")
    pull_always         = optional(bool, true)
    container_mode      = optional(string, "dind")
    visibility          = optional(string, "all")
    workflows           = optional(list(string), null)
    repositories        = optional(list(string), null)
  }))
  default = {
    "arc-runner-set" = {
      runner_group        = null
      create_runner_group = true
      namespace           = "arc-runners"
      create_namespace    = true
      version             = "0.13.0"
      min_runners         = 1
      max_runners         = 5
      runner_image        = "ghcr.io/actions/actions-runner:latest"
      pull_always         = true
      container_mode      = "dind"
      visibility          = "all"
      workflows           = null
      repositories        = null
    }
  }
  validation {
    condition     = var.scale_sets == null || alltrue([for ss in values(var.scale_sets) : can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", ss.version))])
    error_message = "Version format must be <major>.<minor>.<patch> (example: 0.13.0)"
  }
  validation {
    condition     = var.scale_sets == null || alltrue([for ss in values(var.scale_sets) : ss.max_runners >= ss.min_runners])
    error_message = "max_runners must be greater than or equal to min_runners."
  }
  validation {
    condition     = var.scale_sets == null || alltrue([for ss in values(var.scale_sets) : ss.visibility == "all" || ss.visibility == "selected" || ss.visibility == "private"])
    error_message = "Visibility must be 'all', 'selected', or 'private'."
  }
  validation {
    condition     = var.scale_sets == null || alltrue([for ss in values(var.scale_sets) : ss.container_mode == null || ss.container_mode == "dind" || ss.container_mode == "kubernetes"])
    error_message = "Container mode must be null, 'dind', or 'kubernetes'."
  }
}

variable "private_registry" {
  description = "Private container registry URL"
  type        = string
  default     = null
}

variable "private_registry_username" {
  description = "Private container registry username"
  type        = string
  default     = null
}

variable "private_registry_password" {
  description = "Private container registry password"
  type        = string
  sensitive   = true
  default     = null
}
