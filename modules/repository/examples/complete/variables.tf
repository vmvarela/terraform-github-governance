variable "github_token" {
  type        = string
  description = "GitHub personal access token"
}

variable "organization" {
  type        = string
  description = "GitHub organization name"
}

# CI/CD Configuration

variable "ci_webhook_url" {
  type        = string
  description = "CI/CD webhook URL"
}

variable "ci_webhook_secret" {
  type        = string
  description = "CI/CD webhook secret"
}

# Docker Registry
variable "docker_username" {
  type        = string
  description = "Docker registry username"
  default     = ""
}

variable "docker_password" {
  type        = string
  description = "Docker registry password"
  default     = ""
}

# Production Environment
variable "production_api_key" {
  type        = string
  description = "Production API key"
}

variable "production_db_url" {
  type        = string
  description = "Production database URL"
}

# Staging Environment
variable "staging_api_key" {
  type        = string
  description = "Staging API key"
}

variable "staging_db_url" {
  type        = string
  description = "Staging database URL"
}

# NPM Publishing
variable "npm_publish_token" {
  type        = string
  description = "NPM publish token for open source library"
}
