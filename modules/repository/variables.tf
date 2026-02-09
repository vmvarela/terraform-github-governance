variable "allow_auto_merge" {
  description = "Set to true to allow auto-merging pull requests on the repository."
  type        = bool
  default     = false
}

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

variable "allow_merge_commit" {
  description = "Set to false to disable merge commits on the repository."
  type        = bool
  default     = true
}

variable "allow_rebase_merge" {
  description = "Set to false to disable rebase merges on the repository."
  type        = bool
  default     = true
}

variable "allow_squash_merge" {
  description = "Set to false to disable squash merges on the repository."
  type        = bool
  default     = true
}

variable "allow_update_branch" {
  description = "Set to true to always suggest updating pull request branches."
  type        = bool
  default     = false
}

variable "allowed_roles" {
  description = "List of allowed repository roles. Empty list disables validation. Defaults to GitHub built-in roles."
  type        = list(string)
  default     = ["pull", "triage", "push", "maintain", "admin"]
}

variable "archived" {
  description = "Specifies if the repository should be archived. NOTE: currently the API does not support unarchiving."
  type        = bool
  default     = false
}

variable "default_branch" {
  description = "The name of the main branch (e.g., 'main')."
  type        = string
  default     = "main"
}

variable "delete_branch_on_merge" {
  description = "Automatically delete head branch after a pull request is merged."
  type        = bool
  default     = false
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
  description = "Defines CI/CD environments (e.g., 'staging', 'production') with optional required_approvers (teams/users), secrets and variables. Empty or omitted required_approvers disables reviewer protection."
  type = map(object({
    required_approvers = optional(list(string), []) # e.g., ["user:login", "team:slug"]
    secrets            = optional(map(string), {})
    variables          = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = var.environments == null || alltrue([
      for env in values(var.environments != null ? var.environments : {}) : alltrue([
        for approver in lookup(env, "required_approvers", []) : can(regex("^(user|team):.+$", approver))
      ])
    ])
    error_message = "Invalid 'environments.required_approvers' format. All entries must start with 'user:' or 'team:'."
  }
}

variable "github_app_ids" {
  description = "Map of app slug -> app installation ID. Required for branch bypass app actors. Must be provided by parent governance module."
  type        = map(number)
  default     = {}
  # Example: { "renovate" = 333, "dependabot" = 444 }
}

variable "github_team_ids" {
  description = "Map of team slug -> team ID. Required for branch bypass actors and environment reviewers. Must be provided by parent governance module."
  type        = map(number)
  default     = {}
  # Example: { "sre" = 12345, "platform" = 67890 }
}

variable "github_user_ids" {
  description = "Map of user login -> user ID. Required for environment reviewers. Must be provided by parent governance module."
  type        = map(number)
  default     = {}
  # Example: { "alice" = 111, "bob" = 222 }
}

variable "has_discussions" {
  description = "Set to true to enable GitHub Discussions on the repository."
  type        = bool
  default     = false
}

variable "has_issues" {
  description = "Set to true to enable the GitHub Issues features on the repository."
  type        = bool
  default     = true
}

variable "has_projects" {
  description = "Set to true to enable the GitHub Projects features on the repository."
  type        = bool
  default     = true
}

variable "has_wiki" {
  description = "Set to true to enable the GitHub Wiki features on the repository."
  type        = bool
  default     = true
}

variable "homepage_url" {
  description = "URL of a page describing the project."
  type        = string
  default     = null
}

variable "is_template" {
  description = "Mark this repository as a template repository."
  type        = bool
  default     = false
}

variable "merge_commit_message" {
  description = "Default merge commit message. Can be 'PR_BODY', 'PR_TITLE', or 'BLANK'. Applicable only if allow_merge_commit is true."
  type        = string
  default     = null

  validation {
    condition     = var.merge_commit_message == null || try(contains(["PR_BODY", "PR_TITLE", "BLANK"], var.merge_commit_message), false)
    error_message = "merge_commit_message must be one of 'PR_BODY', 'PR_TITLE', or 'BLANK'."
  }
}

variable "merge_commit_title" {
  description = "Default merge commit title. Can be 'PR_TITLE' or 'MERGE_MESSAGE'. Applicable only if allow_merge_commit is true."
  type        = string
  default     = null

  validation {
    condition     = var.merge_commit_title == null || try(contains(["PR_TITLE", "MERGE_MESSAGE"], var.merge_commit_title), false)
    error_message = "merge_commit_title must be one of 'PR_TITLE' or 'MERGE_MESSAGE'."
  }
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
    condition = var.permissions == null || alltrue([
      for k, v in(var.permissions != null ? var.permissions : {}) :
      # 1. Key must be in "user:" or "team:" format
      (can(regex("^user:.+$", k)) || can(regex("^team:.+$", k))) &&
      # 2. Value must be a non-empty string
      (v != null && v != "")
    ])
    error_message = "Invalid 'permissions'. Keys must start with 'user:' or 'team:', and values must be a non-empty string (the role name)."
  }

  validation {
    condition = (
      var.permissions == null ||
      var.allowed_roles == null ||
      (try(length(var.allowed_roles), -1) == 0) ||
      alltrue([
        for role in values(var.permissions != null ? var.permissions : {}) :
        contains(var.allowed_roles, role)
      ])
    )
    error_message = "Permission role must be one of the allowed roles. Check var.allowed_roles or set it to [] to disable validation."
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
  description = "Map of secrets at the REPOSITORY level (global). Keys are secret names, values are secret values."
  type        = map(string)
  default     = {}
  sensitive   = true
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

variable "squash_merge_commit_message" {
  description = "Default squash merge commit message. Can be 'PR_BODY', 'COMMIT_MESSAGES', or 'BLANK'. Applicable only if allow_squash_merge is true."
  type        = string
  default     = null

  validation {
    condition     = var.squash_merge_commit_message == null || try(contains(["PR_BODY", "COMMIT_MESSAGES", "BLANK"], var.squash_merge_commit_message), false)
    error_message = "squash_merge_commit_message must be one of 'PR_BODY', 'COMMIT_MESSAGES', or 'BLANK'."
  }
}

variable "squash_merge_commit_title" {
  description = "Default squash merge commit title. Can be 'PR_TITLE' or 'COMMIT_OR_PR_TITLE'. Applicable only if allow_squash_merge is true."
  type        = string
  default     = null

  validation {
    condition     = var.squash_merge_commit_title == null || try(contains(["PR_TITLE", "COMMIT_OR_PR_TITLE"], var.squash_merge_commit_title), false)
    error_message = "squash_merge_commit_title must be one of 'PR_TITLE' or 'COMMIT_OR_PR_TITLE'."
  }
}

variable "template" {
  description = "Create this repository from a template repository. Use 'owner/repo' format."
  type = object({
    repository           = string # "owner/repo" format
    include_all_branches = optional(bool, false)
  })
  default = null

  validation {
    condition = var.template == null || (
      length(trimspace(try(var.template.repository, ""))) > 0 &&
      can(regex("^[^/]+/[^/]+$", try(var.template.repository, "")))
    )
    error_message = "Invalid 'template.repository' format. Use 'owner/repo' with exactly one '/'."
  }
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
    condition     = contains(["public", "private", "internal"], coalesce(var.visibility, "private"))
    error_message = "Visibility must be one of 'public', 'private', or 'internal'."
  }
}

variable "vulnerability_alerts" {
  description = "Set to true to enable security alerts for vulnerable dependencies."
  type        = bool
  default     = true
}

variable "web_commit_signoff_required" {
  description = "Require contributors to sign off on web-based commits."
  type        = bool
  default     = false
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
  description = "Optional workspace/namespace for logical grouping of repositories. If provided, will be stored as a custom property."
  type        = string
  default     = null
}
