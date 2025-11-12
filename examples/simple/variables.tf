variable "name" {
  description = "GitHub organization name"
  type        = string
}

variable "billing_email" {
  description = "Billing email address for the organization"
  type        = string
}

variable "github_token" {
  description = "GitHub Personal Access Token with admin:org and repo scopes"
  type        = string
  sensitive   = true
}
