variable "organization_name" {
  description = "Organization identifier for the module"
  type        = string
  default     = "large-scale-org"
}

variable "github_token" {
  description = "GitHub Personal Access Token with appropriate scopes"
  type        = string
  sensitive   = true
}

variable "billing_email" {
  description = "Billing email for the organization"
  type        = string
}

variable "slack_webhook_encrypted" {
  description = "Encrypted Slack webhook URL (base64 encoded with GitHub public key)"
  type        = string
  sensitive   = true
}

variable "sonarqube_token_encrypted" {
  description = "Encrypted SonarQube token (base64 encoded with GitHub public key)"
  type        = string
  sensitive   = true
}

variable "npm_token_encrypted" {
  description = "Encrypted NPM registry token (base64 encoded with GitHub public key)"
  type        = string
  sensitive   = true
}
