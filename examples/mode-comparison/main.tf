# Example: Organization Mode vs Project Mode Comparison

# ============================================================================
# ORGANIZATION MODE - Full organization management
# ============================================================================
module "organization" {
  source = "../../"

  name = "my-company"
  mode = "organization" # Manages entire organization

  # Define some repositories
  repositories = {
    "api-gateway" = {
      description = "API Gateway service"
      visibility  = "private"
    }
    "web-app" = {
      description = "Web application"
      visibility  = "private"
    }
  }

  # Runner groups can reference ANY repository in the organization
  runner_groups = {
    "production-runners" = {
      visibility = "selected"
      repositories = [
        "api-gateway",        # Managed by this module
        "web-app",            # Managed by this module
        "legacy-monolith",    # NOT managed by this module (existing repo)
        "third-party-service" # NOT managed by this module (existing repo)
      ]
    }
    "all-repos-runners" = {
      visibility = "all" # Available to ALL org repos
    }
  }

  # Organization-wide variables (or selected repos)
  variables = {
    "ORG_DOMAIN"   = "my-company.com"
    "API_ENDPOINT" = "https://api.my-company.com"
  }

  # Organization-wide secrets
  secrets_encrypted = {
    "NPM_TOKEN"    = "encrypted_value_here"
    "DOCKER_TOKEN" = "encrypted_value_here"
  }
}

# ============================================================================
# PROJECT MODE - Scoped project management
# ============================================================================
module "project_mobile" {
  source = "../../"

  name       = "mobile-team"
  mode       = "project"    # Project mode with restrictions
  github_org = "my-company" # Parent organization
  spec       = "mobile-%s"  # Prefix for repository names

  # Define project repositories (will be named: mobile-ios, mobile-android)
  repositories = {
    "ios" = {
      description = "iOS mobile app"
      visibility  = "private"
    }
    "android" = {
      description = "Android mobile app"
      visibility  = "private"
    }
  }

  # Runner groups AUTOMATICALLY scoped to project repos only
  runner_groups = {
    "mobile-ci" = {
      # NO 'repositories' field needed or allowed!
      # Automatically includes ONLY: mobile-ios, mobile-android
      # Cannot reference repos outside this project
    }
  }

  # Variables AUTOMATICALLY scoped to project repos
  variables = {
    "MOBILE_API_KEY" = "project-specific-key"
    "APP_VERSION"    = "2.1.0"
    # These are ONLY visible to mobile-ios and mobile-android
  }

  # Secrets AUTOMATICALLY scoped to project repos
  secrets_encrypted = {
    "FIREBASE_TOKEN" = "encrypted_value_here"
    # Only accessible by mobile-ios and mobile-android
  }
}

module "project_backend" {
  source = "../../"

  name       = "backend-services"
  mode       = "project"
  github_org = "my-company"
  spec       = "backend-%s"

  repositories = {
    "api" = {
      description = "REST API service"
      visibility  = "private"
    }
    "workers" = {
      description = "Background workers"
      visibility  = "private"
    }
  }

  runner_groups = {
    "backend-deploy" = {
      # Automatically: backend-api, backend-workers
      # Cannot access mobile-ios, mobile-android, or any other repos
    }
  }

  variables = {
    "DATABASE_URL" = "postgres://..."
    # Isolated from mobile team variables
  }
}

# ============================================================================
# OUTPUT EXAMPLES
# ============================================================================

# Organization mode: Access any repository
output "org_all_repositories" {
  description = "Organization can access all repos by name"
  value = {
    managed = module.organization.repository_ids
    # Can also include external repos via data sources
  }
}

# Project mode: Only project repositories
output "project_mobile_repos" {
  description = "Project only sees its own repositories"
  value = {
    managed = module.project_mobile.repository_names
    # mobile-ios, mobile-android
    # Cannot see backend-* or organization repos
  }
}

output "project_backend_repos" {
  description = "Another project's isolated repositories"
  value = {
    managed = module.project_backend.repository_names
    # backend-api, backend-workers
    # Cannot see mobile-* or organization repos
  }
}

# ============================================================================
# KEY DIFFERENCES SUMMARY
# ============================================================================

# ORGANIZATION MODE:
# ✓ Full organization access
# ✓ Can reference ANY repository by name
# ✓ Runner groups can include external repos
# ✓ Secrets/variables can be org-wide
# ✓ Flexible but requires careful scoping

# PROJECT MODE:
# ✓ Strict project boundaries
# ✓ Can ONLY access project repositories
# ✓ Runner groups auto-scoped (no config needed)
# ✓ Secrets/variables auto-scoped
# ✓ Perfect for team isolation
# ✓ Simpler configuration (less repetition)
# ✗ Cannot reference repos outside project
