variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_token" {
  description = "GitHub token"
  type        = string
  sensitive   = true
  default     = null
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
