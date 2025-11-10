variable "github_token" {
  type        = string
  description = "The GitHub token with permissions to manage repositories in the specified organization."
  sensitive   = true
}

# --- 1. Core Configuration ---

variable "name" {
  type        = string
  description = "The name of the repository. Must be unique within its workspace (organization, group, or project)."
}

variable "description" {
  type        = string
  description = "A short, friendly description of the repository's purpose."
  default     = null
}

variable "visibility" {
  type        = string
  description = "Visibility of the repository. Valid values: 'public', 'private', or 'internal'."
  default     = "private"

  validation {
    condition     = contains(["public", "private", "internal"], var.visibility)
    error_message = "Visibility must be one of 'public', 'private', or 'internal'."
  }
}

variable "default_branch" {
  type        = string
  description = "The name of the main branch (e.g., 'main')."
  default     = "main"
}

variable "organization" {
  type        = string
  description = "GitHub organization name where the repository will be created."
}

variable "workspace" {
  type        = string
  description = "Optional workspace/namespace for logical grouping and governance (e.g., 'platform-services', 'data-team'). Stored as a custom property."
  default     = null
}

variable "topics" {
  type        = list(string)
  description = "A list of GitHub topics to classify the repository."
  default     = []
}

variable "properties" {
  type        = map(string)
  description = "Generic key-value metadata properties."
  default     = {}
}

# --- 2. Template ---

variable "is_template" {
  type        = bool
  description = "Mark this repository as a template repository."
  default     = false
}

variable "template" {
  type = object({
    repository           = string # "owner/repo" format
    include_all_branches = optional(bool, false)
  })
  description = "Create this repository from a template repository. Use 'owner/repo' format."
  default     = null
}

# --- 3. Access & Permissions ---

variable "permissions" {
  type        = map(string)
  description = "Map of permission grants. Key is the entity ('user:name' or 'team:slug'), Value is the provider-specific role name (e.g., 'write', 'admin', 'my-custom-role')."
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

variable "deploy_keys" {
  type = map(object({
    key       = string # The SSH public key
    read_only = optional(bool, false)
  }))
  description = "Map of deploy keys to add. The map key is the title of the deploy key."
  default     = {}
}

variable "allowed_roles" {
  type        = list(string)
  description = "List of allowed repository roles for validation. If empty, no validation is performed. Default includes GitHub's built-in roles."
  default     = ["pull", "triage", "push", "maintain", "admin"]
}

# --- 4. Automation (Global) ---

variable "webhooks" {
  type = map(object({
    url    = string
    events = list(string) # Generic events: 'push', 'pull_request', 'issue'
    secret = optional(string, null)
  }))
  description = "Map of webhooks to configure. Key is the webhook name."
  default     = {}
}

variable "repository_secrets" {
  type        = map(string)
  description = "Map of secrets at the REPOSITORY level (global). Keys are secret names, values contain the secret value (sensitive) and optional sensitivity flag."
  default     = {}
}

variable "repository_variables" {
  type        = map(string)
  description = "Map of variables at the REPOSITORY level (global)."
  default     = {}
}

# --- 5. CI/CD Environments ---

variable "environments" {
  type        = any
  description = "Defines CI/CD environments (e.g., 'staging', 'production') with optional reviewers (required_approvers), secrets, and variables. Empty or omitted 'required_approvers' disables reviewer enforcement."
  default     = {}
}

# --- 6. Branch Protection (flattened) ---

variable "protected_branches" {
  type        = list(string)
  description = "Branches to protect. Empty list disables the ruleset. Patterns like 'main', 'release/*'."
  default     = []
}

variable "allow_bypass" {
  type        = list(string)
  description = "Actors allowed to bypass protections: 'org-admin', 'role:maintain|write|admin', 'team:slug', 'app:slug'."
  default     = []

  validation {
    condition = alltrue([
      for actor in var.allow_bypass :
      can(regex("^(org-admin|role:(maintain|write|admin)|team:[a-zA-Z0-9_-]+|app:[a-zA-Z0-9_-]+)$", actor))
    ])
    error_message = "Invalid 'allow_bypass' format. Valid: 'org-admin', 'role:maintain|write|admin', 'team:slug', 'app:slug'."
  }
}

variable "required_approvals" {
  type        = number
  description = "Number of required PR approvals. 0 disables PR requirement."
  default     = 1

  validation {
    condition     = var.required_approvals >= 0
    error_message = "'required_approvals' must be 0 or greater."
  }
}

variable "required_checks" {
  type        = list(string)
  description = "List of required status check contexts. Strict policy is always enforced."
  default     = []
}

variable "prevent_force_push" {
  type        = bool
  description = "Prevent force-pushes (non-fast-forward)."
  default     = true
}

variable "prevent_branch_deletion" {
  type        = bool
  description = "Prevent deletion of protected branches."
  default     = true
}
