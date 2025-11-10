variable "repository" {
  description = "The repository of the environment."
  type        = string
}

variable "environment" {
  description = "The name of the environment."
  type        = string
}

variable "wait_timer" {
  description = "Amount of time to delay a job after the job is initially triggered."
  type        = number
  default     = null
}

variable "can_admins_bypass" {
  description = "Can repository admins bypass the environment protections. Defaults to `true`."
  type        = bool
  default     = true
}

variable "prevent_self_review" {
  description = "Whether or not a user who created the job is prevented from approving their own job. Defaults to `false`."
  type        = bool
  default     = false
}

variable "reviewers_teams" {
  description = "Up to 6 IDs for teams who may review jobs that reference the environment. Reviewers must have at least read access to the repository. Only one of the required reviewers needs to approve the job for it to proceed."
  type        = set(string)
  default     = []
}

variable "reviewers_users" {
  description = "Up to 6 IDs for users who may review jobs that reference the environment. Reviewers must have at least read access to the repository. Only one of the required reviewers needs to approve the job for it to proceed."
  type        = set(string)
  default     = []
}

variable "protected_branches" {
  description = "Whether only branches with branch protection rules can deploy to this environment."
  type        = bool
  default     = null
}

variable "custom_branch_policies" {
  description = "Whether only branches that match the specified name patterns can deploy to this environment."
  type        = set(string)
  default     = []
}

variable "secrets" {
  description = "(Optional)"
  type        = map(string)
  default     = {}
}

variable "secrets_encrypted" {
  description = "(Optional)"
  type        = map(string)
  default     = {}
}

variable "variables" {
  description = "(Optional)"
  type        = map(string)
  default     = {}
}
