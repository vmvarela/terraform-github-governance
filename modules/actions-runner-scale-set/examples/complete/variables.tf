variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_app_id" {
  description = "GitHub App ID"
  type        = number
  sensitive   = true
}

variable "github_app_private_key" {
  description = "GitHub App private key (PEM format)"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = number
  sensitive   = true
}

variable "kubernetes_config_path" {
  description = "Path to the Kubernetes configuration file"
  type        = string
  default     = "~/.kube/config"
}

variable "kubernetes_config_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "docker-desktop"
}

variable "private_registry" {
  description = "URL of the private container registry"
  type        = string
  default     = null
}

variable "private_registry_username" {
  description = "Username for the private container registry"
  type        = string
  default     = null
}

variable "private_registry_password" {
  description = "Password for the private container registry"
  type        = string
  default     = null
}
