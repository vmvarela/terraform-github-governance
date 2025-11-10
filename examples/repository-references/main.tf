# Example: Using repository names in runner groups and rulesets

# This example demonstrates how to reference repositories by name
# instead of hardcoding numeric IDs

module "github" {
  source = "../.."

  name = "my-org"
  mode = "organization"

  # Define repositories
  repositories = {
    "backend-api" = {
      description = "Backend API service"
      visibility  = "private"
    }
    "frontend-app" = {
      description = "Frontend application"
      visibility  = "private"
    }
    "shared-libs" = {
      description = "Shared libraries"
      visibility  = "private"
    }
  }

  # Runner groups with repository references by NAME
  runner_groups = {
    "production-runners" = {
      visibility = "selected"
      # Reference repositories by their name - IDs are resolved automatically
      repositories = [
        "backend-api",
        "frontend-app"
      ]
    }
    "development-runners" = {
      visibility = "selected"
      repositories = [
        "shared-libs"
      ]
    }
  }

  # Rulesets can also reference repositories
  rulesets = {
    "protect-main" = {
      enforcement = "active"
      target      = "branch"
      include     = ["main"]

      rules = {
        required_linear_history = true
        required_signatures     = true
        pull_request = {
          required_approving_review_count = 2
        }
      }

      # You can also specify repositories if not using organization-wide rules
      # repositories = ["backend-api", "frontend-app"]
    }
  }
}

# Access repository IDs from output if needed
output "example_repository_ids" {
  description = "Example showing how to access repository IDs"
  value = {
    backend_id  = module.github.repository_ids["backend-api"]
    frontend_id = module.github.repository_ids["frontend-app"]
    all_ids     = module.github.repository_ids
  }
}

# Use repository names in expressions
output "example_repository_names" {
  description = "Mapping from keys to actual repository names"
  value       = module.github.repository_names
}
