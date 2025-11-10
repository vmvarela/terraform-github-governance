variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token with appropriate permissions"
  type        = string
  sensitive   = true
  default     = null
}

# variable "github_app_id" {
#   description = "GitHub App ID (alternative to token)"
#   type        = number
#   sensitive   = true
#   default     = null
# }
#
# variable "github_app_private_key" {
#   description = "GitHub App private key in PEM format (alternative to token)"
#   type        = string
#   sensitive   = true
#   default     = null
# }
#
# variable "github_app_installation_id" {
#   description = "GitHub App Installation ID (alternative to token)"
#   type        = number
#   sensitive   = true
#   default     = null
# }

variable "billing_email" {
  description = "Billing email for the GitHub organization"
  type        = string
}

variable "private_registry" {
  description = "Private container registry URL (optional)"
  type        = string
  default     = null
}

variable "private_registry_username" {
  description = "Private container registry username (optional)"
  type        = string
  default     = null
}

variable "private_registry_password" {
  description = "Private container registry password (optional)"
  type        = string
  sensitive   = true
  default     = null
}
