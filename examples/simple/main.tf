terraform {
  required_version = ">= 1.6"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = var.name
  token = var.github_token
}

module "github" {
  source = "../../"

  mode = "organization"
  name = var.name

  settings = {
    billing_email                   = var.billing_email
    description                     = "My GitHub Organization"
    default_repository_permission   = "read"
    members_can_create_repositories = false
  }

  repositories = {
    "my-app" = {
      description = "My application repository"
      visibility  = "private"
      has_issues  = true
      has_wiki    = false
    }

    "documentation" = {
      description = "Organization documentation"
      visibility  = "public"
      has_issues  = false
      has_wiki    = true
    }
  }

  runner_groups = {
    "default-runners" = {
      visibility                = "all"
      allow_public_repositories = false
    }
  }

  variables = {
    "ENVIRONMENT" = "production"
  }
}
