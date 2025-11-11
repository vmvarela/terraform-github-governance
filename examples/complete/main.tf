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
module "github_governance" {
  source = "../.."

  # Core Configuration
  name = var.name
  mode = "organization"

  # Provide empty defaults to avoid API calls that may fail on empty/new organizations
  info_repositories = []
  info_organization = {
    plan = var.github_plan
  }

  # Organization Settings
  settings = {
    # General
    billing_email             = var.billing_email
    description               = "Comprehensive example showcasing all module features"
    company                   = "Example Corp"
    blog                      = "https://example.com"
    email                     = var.billing_email
    twitter                   = "example"
    location                  = "San Francisco, CA"
    has_repository_projects   = true
    has_organization_projects = true

    # Member Privileges
    members_can_create_repositories         = true
    members_can_create_public_repositories  = true
    members_can_create_private_repositories = true
    members_can_create_pages                = true
    members_can_create_public_pages         = true
    members_can_create_private_pages        = true
    members_can_fork_private_repositories   = true

    # Base Permissions
    default_repository_permission = "read"

    # Pages
    members_allowed_repository_creation_type = "all"

    # Web Commit Signoff
    web_commit_signoff_required = true

    # Security Defaults
    advanced_security_enabled_for_new_repositories               = true
    dependabot_alerts_enabled_for_new_repositories               = true
    dependabot_security_updates_enabled_for_new_repositories     = true
    dependency_graph_enabled_for_new_repositories                = true
    secret_scanning_enabled_for_new_repositories                 = true
    secret_scanning_push_protection_enabled_for_new_repositories = true
  }

  # Repositories with varied configurations
  repositories = {
    # Public repository - Open source project
    "public-library" = {
      alias        = "public-lib"
      description  = "Open source library with full features"
      visibility   = "public"
      homepage_url = "https://example.com/public-library"
      topics       = ["library", "opensource", "example"]

      # Repository Features
      has_issues      = true
      has_discussions = true
      has_projects    = true
      has_wiki        = true
      has_downloads   = true

      # Branch Protection
      default_branch = "main"
      auto_init      = true

      # Security
      vulnerability_alerts = true

      # Pages
      pages = {
        source = {
          branch = "gh-pages"
          path   = "/"
        }
      }
    }

    # Private repository - Internal project
    "private-api" = {
      description = "Internal API service"
      visibility  = "private"
      topics      = ["api", "backend", "microservice"]

      has_issues   = true
      has_projects = true

      # Template repository settings
      is_template = false

      # Archive settings
      archived = false

      # Security scanning
      vulnerability_alerts = true

      # Allow merge options
      allow_merge_commit     = true
      allow_squash_merge     = true
      allow_rebase_merge     = false
      allow_auto_merge       = true
      delete_branch_on_merge = true

      # Merge commit settings
      merge_commit_title          = "MERGE_MESSAGE"
      merge_commit_message        = "PR_TITLE"
      squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
      squash_merge_commit_message = "COMMIT_MESSAGES"
    }

    # Internal tools repository
    "internal-tools" = {
      description = "Internal development tools"
      visibility  = "private" # Changed from "internal" (enterprise-only) to "private"
      topics      = ["tools", "internal", "devtools"]

      has_issues   = true
      has_projects = false
      has_wiki     = false

      vulnerability_alerts   = true
      allow_squash_merge     = true
      delete_branch_on_merge = true
    }

    # Repository with advanced branch protection
    "critical-app" = {
      description = "Production critical application"
      visibility  = "private"
      topics      = ["production", "critical", "app"]

      has_issues   = true
      has_projects = true

      vulnerability_alerts = true

      # Strict merge settings
      allow_merge_commit     = false
      allow_squash_merge     = true
      allow_rebase_merge     = false
      allow_auto_merge       = false
      delete_branch_on_merge = true

      # Require conversation resolution
      allow_update_branch = true
    }

    # Documentation repository
    "docs" = {
      description  = "Organization documentation"
      visibility   = "public"
      homepage_url = "https://docs.example.com"
      topics       = ["documentation", "guides", "reference"]

      has_issues      = true
      has_discussions = true
      has_wiki        = false
      has_projects    = false

      # Optimized for documentation
      pages = {
        source = {
          branch = "main"
          path   = "/docs"
        }
      }

      # Simple merge strategy
      allow_merge_commit     = true
      allow_squash_merge     = false
      allow_rebase_merge     = false
      delete_branch_on_merge = true
    }
  }

  # GitHub Actions Runner Groups
  runner_groups = {
    # Default runner group for all repos
    "default" = {
      visibility                 = "all"
      allows_public_repositories = false
    }

    # Production runners with restrictions
    "production" = {
      visibility                 = "selected"
      repositories               = ["critical-app", "private-api"]
      allows_public_repositories = false

      # Restrict to specific workflows
      restricted_to_workflows = true
      selected_workflows = [
        "example/deploy-production/.github/workflows/deploy.yml@refs/heads/main"
      ]
    }

    # CI runners for all private repos
    "ci-runners" = {
      visibility                 = "selected"
      repositories               = ["private-api", "critical-app", "internal-tools"]
      allows_public_repositories = false
    }
  }

  # Organization Variables
  variables = {
    # Environment variables
    "ENVIRONMENT" = "production"
    "REGION"      = "us-west-2"
    "LOG_LEVEL"   = "info"

    # API endpoints
    "API_BASE_URL" = "https://api.example.com"
    "CDN_URL"      = "https://cdn.example.com"

    # Build configuration
    "NODE_VERSION"   = "20"
    "PYTHON_VERSION" = "3.11"
    "GO_VERSION"     = "1.21"
  }

  # Encrypted Secrets (base64 encoded with organization public key)
  # Use GitHub CLI to encrypt: gh secret set SECRET_NAME --body "value"
  # Filter out empty values as they are not valid encrypted secrets
  secrets_encrypted = {
    for k, v in {
      "DEPLOY_TOKEN" = var.deploy_token_encrypted
      "NPM_TOKEN"    = var.npm_token_encrypted
    } : k => v if v != ""
  }

  # Organization Webhooks (requires Team+ plan)
  webhooks = var.github_plan != "free" ? {
    "ci-notifications" = {
      url          = "https://ci.example.com/webhooks/github"
      content_type = "json"
      insecure_ssl = false
      active       = true
      events = [
        "push",
        "pull_request",
        "workflow_run",
        "deployment",
        "deployment_status"
      ]
    }

    "security-alerts" = {
      url          = "https://security.example.com/webhooks/github"
      content_type = "json"
      insecure_ssl = false
      active       = true
      events = [
        "code_scanning_alert",
        "dependabot_alert",
        "secret_scanning_alert",
        "security_advisory"
      ]
    }
  } : null

  # Custom Repository Roles (requires Enterprise plan)
  repository_roles = var.github_plan == "enterprise" ? {
    "deployer" = {
      base_role   = "write"
      description = "Can deploy to production environments"
      permissions = [
        "read",
        "write",
        "create_deployment",
        "read_deployment",
        "write_deployment"
      ]
    }

    "security-reviewer" = {
      base_role   = "read"
      description = "Can review security findings"
      permissions = [
        "read",
        "read_security",
        "write_security"
      ]
    }
  } : null

  # Organization Rulesets (requires Team+ plan)
  rulesets = var.github_plan != "free" ? {
    # Protect main branches across all repos
    "protect-main-branches" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main", "refs/heads/master"]
          exclude = []
        }
      }

      rules = {
        # Require pull requests
        pull_request = {
          required_approving_review_count   = 1
          dismiss_stale_reviews_on_push     = true
          require_code_owner_review         = false
          require_last_push_approval        = false
          required_review_thread_resolution = true
        }

        # Require status checks
        required_status_checks               = { "ci/tests" = "" }
        strict_required_status_checks_policy = true

        # Basic protections
        deletion                = true
        non_fast_forward        = true
        required_linear_history = false
        required_signatures     = false
      }
    }

    # Enforce workflow requirements for production
    "required-workflows" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
        repository_name = {
          include = ["critical-app", "private-api"]
          exclude = []
        }
      }

      rules = {
        required_workflows = [
          {
            repository = "my-org/.github"
            path       = ".github/workflows/security-scan.yml"
            ref        = "refs/heads/main"
          }
        ]
      }
    }
  } : null
}
