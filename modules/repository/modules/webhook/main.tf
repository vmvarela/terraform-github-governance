terraform {
  required_version = ">= 1.6"

  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.6.0"
    }
  }
}

# repository_webhook
resource "github_repository_webhook" "this" {
  repository = var.repository
  active     = true
  configuration {
    url          = var.url
    content_type = var.content_type
    insecure_ssl = var.insecure_ssl
    secret       = var.secret
  }
  events = var.events
}
