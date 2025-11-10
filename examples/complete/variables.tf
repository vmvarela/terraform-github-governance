variable "name" {
  description = "Organization name"
  type        = string
}

variable "billing_email" {
  description = "Billing email for the organization"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token with appropriate scopes"
  type        = string
  sensitive   = true
}

variable "github_plan" {
  description = "GitHub organization plan (free, team, business, or enterprise)"
  type        = string
  default     = "free"

  validation {
    condition     = contains(["free", "team", "business", "enterprise"], var.github_plan)
    error_message = "Plan must be one of: free, team, business, or enterprise."
  }
}

variable "deploy_token_encrypted" {
  description = "Encrypted deploy token (base64 encoded with organization public key)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "npm_token_encrypted" {
  description = "Encrypted NPM token (base64 encoded with organization public key)"
  type        = string
  default     = ""
  sensitive   = true
}
