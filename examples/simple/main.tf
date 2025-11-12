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
    # Using preset: secure-service (automatically configures security features)
    "my-api" = {
      preset      = "secure-service"
      description = "Backend API service"
    }

    # Using preset: public-library (perfect for open source projects)
    "my-library" = {
      preset      = "public-library"
      description = "Reusable component library"
    }

    # Using preset: documentation (optimized for GitHub Pages)
    "docs-site" = {
      preset      = "documentation"
      description = "Documentation website"
    }

    # Manual configuration (no preset)
    "legacy-app" = {
      description = "Legacy application"
      visibility  = "private"
      has_issues  = true
      has_wiki    = false
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
