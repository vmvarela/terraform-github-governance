variable "ci_webhook_secret" {
  description = "CI/CD webhook secret"
  type        = string
}

variable "ci_webhook_url" {
  description = "CI/CD webhook URL"
  type        = string
}

variable "docker_password" {
  description = "Docker registry password"
  type        = string
  default     = ""
}

variable "docker_username" {
  description = "Docker registry username"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub personal access token"
  type        = string
}

variable "npm_publish_token" {
  description = "NPM publish token for open source library"
  type        = string
}

variable "organization" {
  description = "GitHub organization name"
  type        = string
}

variable "production_api_key" {
  description = "Production API key"
  type        = string
}

variable "production_db_url" {
  description = "Production database URL"
  type        = string
}

variable "staging_api_key" {
  description = "Staging API key"
  type        = string
}

variable "staging_db_url" {
  description = "Staging database URL"
  type        = string
}
