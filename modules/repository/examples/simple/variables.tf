variable "allow_bypass" {
  description = "Actors allowed to bypass protections: 'org-admin', 'role:maintain|write|admin', 'team:slug', 'app:slug'."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for actor in var.allow_bypass :
      can(regex("^(org-admin|role:(maintain|write|admin)|team:[a-zA-Z0-9_-]+|app:[a-zA-Z0-9_-]+)$", actor))
    ])
    error_message = "Invalid 'allow_bypass' format. Valid: 'org-admin', 'role:maintain|write|admin', 'team:slug', 'app:slug'."
  }
}

variable "allowed_roles" {
  description = "List of allowed repository roles for validation. If empty, no validation is performed. Default includes GitHub's built-in roles."
  type        = list(string)
  default     = ["pull", "triage", "push", "maintain", "admin"]
}

variable "default_branch" {
  description = "The name of the main branch (e.g., 'main')."
  type        = string
  default     = "main"
}

variable "deploy_keys" {
  description = "Map of deploy keys to add. The map key is the title of the deploy key."
  type = map(object({
    key       = string # The SSH public key
    read_only = optional(bool, false)
  }))
  default = {}
}

variable "description" {
  description = "A short, friendly description of the repository's purpose."
  type        = string
  default     = null
}

variable "environments" {
  description = "Defines CI/CD environments (e.g., 'staging', 'production') with optional reviewers (required_approvers), secrets, and variables. Empty or omitted 'required_approvers' disables reviewer enforcement."
  type        = any
  default     = {}
}

variable "github_token" {
  description = "The GitHub token with permissions to manage repositories in the specified organization."
  type        = string
  sensitive   = true
}

variable "is_template" {
  description = "Mark this repository as a template repository."
  type        = bool
  default     = false
}

variable "name" {
  description = "The name of the repository. Must be unique within its workspace (organization, group, or project)."
  type        = string
}

variable "organization" {
  description = "GitHub organization name where the repository will be created."
  type        = string
}

variable "permissions" {
  description = "Map of permission grants. Key is the entity ('user:name' or 'team:slug'), Value is the provider-specific role name (e.g., 'write', 'admin', 'my-custom-role')."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.permissions :
      # 1. Key must be in "user:" or "team:" format
      (can(regex("^user:.+$", k)) || can(regex("^team:.+$", k))) &&
      # 2. Value must be a non-empty string
      (v != null && v != "")
    ])
    error_message = "Invalid 'permissions'. Keys must start with 'user:' or 'team:', and values must be a non-empty string (the role name)."
  }

  validation {
    condition = length(var.allowed_roles) == 0 || alltrue([
      for k, v in var.permissions : contains(var.allowed_roles, v)
    ])
    error_message = "Permission role must be one of the allowed roles: ${join(", ", var.allowed_roles)}. To use custom roles, add them to 'allowed_roles' or set it to [] to disable validation."
  }
}

variable "prevent_branch_deletion" {
  description = "Prevent deletion of protected branches."
  type        = bool
  default     = true
}

variable "prevent_force_push" {
  description = "Prevent force-pushes (non-fast-forward)."
  type        = bool
  default     = true
}

variable "properties" {
  description = "Generic key-value metadata properties."
  type        = map(string)
  default     = {}
}

variable "protected_branches" {
  description = "Branches to protect. Empty list disables the ruleset. Patterns like 'main', 'release/*'."
  type        = list(string)
  default     = []
}

variable "repository_secrets" {
  description = "Map of secrets at the REPOSITORY level (global). Keys are secret names, values contain the secret value (sensitive) and optional sensitivity flag."
  type        = map(string)
  default     = {}
}

variable "repository_variables" {
  description = "Map of variables at the REPOSITORY level (global)."
  type        = map(string)
  default     = {}
}

variable "required_approvals" {
  description = "Number of required PR approvals. 0 disables PR requirement."
  type        = number
  default     = 1

  validation {
    condition     = var.required_approvals >= 0
    error_message = "'required_approvals' must be 0 or greater."
  }
}

variable "required_checks" {
  description = "List of required status check contexts. Strict policy is always enforced."
  type        = list(string)
  default     = []
}

variable "template" {
  description = "Create this repository from a template repository. Use 'owner/repo' format."
  type = object({
    repository           = string # "owner/repo" format
    include_all_branches = optional(bool, false)
  })
  default = null
}

variable "topics" {
  description = "A list of GitHub topics to classify the repository."
  type        = list(string)
  default     = []
}

variable "visibility" {
  description = "Visibility of the repository. Valid values: 'public', 'private', or 'internal'."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "Visibility must be one of 'public', 'private', or 'internal'."
  }
}

variable "webhooks" {
  description = "Map of webhooks to configure. Key is the webhook name."
  type = map(object({
    url    = string
    events = list(string) # Generic events: 'push', 'pull_request', 'issue'
    secret = optional(string, null)
  }))
  default = {}
}

variable "workspace" {
  description = "Optional workspace/namespace for logical grouping and governance (e.g., 'platform-services', 'data-team'). Stored as a custom property."
  type        = string
  default     = null
}
