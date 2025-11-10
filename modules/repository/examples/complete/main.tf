terraform {
  required_version = ">= 1.6"

  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.6.0"
    }
  }
}

provider "github" {
  # GitHub token can be set via GITHUB_TOKEN environment variable
  # or you can set the owner here
  # owner = "your-github-username"
}

module "complete_repository" {
  source = "../.."

  # Basic repository settings
  name           = "my-complete-repo"
  description    = "A comprehensive repository showcasing all module features"
  visibility     = "private"
  default_branch = "main"
  homepage       = "https://example.com"

  # Repository features
  has_issues   = true
  has_wiki     = true
  has_projects = true
  is_template  = false

  # Topics for discoverability
  topics = ["terraform", "github", "devops", "infrastructure", "automation"]

  # Merge strategies
  allow_merge_commit          = true
  allow_squash_merge          = true
  allow_rebase_merge          = false
  allow_auto_merge            = true
  delete_branch_on_merge      = true
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "COMMIT_MESSAGES"
  merge_commit_title          = "PR_TITLE"
  merge_commit_message        = "PR_BODY"

  # Security settings
  enable_vulnerability_alerts            = true
  enable_dependabot_security_updates     = true
  enable_advanced_security               = true
  enable_secret_scanning                 = true
  enable_secret_scanning_push_protection = true

  # GitHub Actions configuration
  enable_actions           = true
  actions_access_level     = "organization"
  actions_allowed_policy   = "selected"
  actions_allowed_github   = true
  actions_allowed_verified = true
  actions_allowed_patterns = ["actions/*", "docker/*"]

  # Branches
  branches = {
    "develop"    = "main"
    "staging"    = "develop"
    "production" = "main"
  }

  # GitHub Actions secrets
  secrets = {
    "DOCKER_USERNAME" = "myuser"
    "NPM_TOKEN"       = "npm_token_value"
  }

  # GitHub Actions variables
  variables = {
    "ENVIRONMENT"   = "production"
    "DEPLOY_REGION" = "us-east-1"
    "SERVICE_NAME"  = "my-service"
  }

  # Dependabot secrets (copy from actions secrets)
  dependabot_copy_secrets = true

  # Deploy keys
  deploy_keys = {
    "ci-cd-key" = {
      public_key = null  # Will be auto-generated
      read_only  = false # Write access for deployments
    }
    "monitoring-key" = {
      public_key = null
      read_only  = true # Read-only access
    }
  }

  # Issue labels
  issue_labels = {
    "bug"              = "Something isn't working"
    "enhancement"      = "New feature or request"
    "documentation"    = "Documentation improvements"
    "security"         = "Security-related issues"
    "performance"      = "Performance improvements"
    "good-first-issue" = "Good for newcomers"
    "help-wanted"      = "Extra attention needed"
  }
  issue_labels_colors = {
    "bug"         = "d73a4a"
    "enhancement" = "a2eeef"
    "security"    = "ee0701"
    "performance" = "0e8a16"
  }

  # Autolink references
  autolink_references = {
    "JIRA-"   = "https://jira.example.com/browse/<num>"
    "TICKET-" = "https://tickets.example.com/issue/<num>"
  }

  # Collaborators (users and teams)
  users = {
    "user1" = "push"
    "user2" = "maintain"
  }
  teams = {
    "team-developers" = "push"
    "team-reviewers"  = "maintain"
    "team-admins"     = "admin"
  }

  # Environments
  environments = {
    "development" = {
      wait_timer             = 0
      can_admins_bypass      = true
      prevent_self_review    = false
      reviewers_users        = []
      protected_branches     = false
      custom_branch_policies = false
      variables = {
        "API_URL"    = "https://dev-api.example.com"
        "DEBUG_MODE" = "true"
      }
      secrets = {
        "DB_PASSWORD" = "dev_password"
      }
    }
    "staging" = {
      wait_timer             = 5
      can_admins_bypass      = false
      prevent_self_review    = true
      reviewers_users        = ["user1"]
      protected_branches     = true
      custom_branch_policies = false
      variables = {
        "API_URL"    = "https://staging-api.example.com"
        "DEBUG_MODE" = "false"
      }
      secrets = {
        "DB_PASSWORD" = "staging_password"
      }
    }
    "production" = {
      wait_timer             = 30
      can_admins_bypass      = false
      prevent_self_review    = true
      reviewers_users        = ["user1", "user2"]
      protected_branches     = true
      custom_branch_policies = false
      variables = {
        "API_URL"    = "https://api.example.com"
        "DEBUG_MODE" = "false"
      }
      secrets = {
        "DB_PASSWORD" = "production_password"
      }
    }
  }

  # Repository files
  files = [
    {
      file           = ".gitignore"
      content        = <<-EOT
        # Terraform
        *.tfstate
        *.tfstate.backup
        .terraform/

        # Environment files
        .env
        .env.local

        # IDE
        .vscode/
        .idea/
      EOT
      commit_message = "Add .gitignore file"
      commit_author  = "Terraform"
      commit_email   = "terraform@example.com"
    },
    {
      file           = "CONTRIBUTING.md"
      content        = <<-EOT
        # Contributing Guidelines

        Thank you for considering contributing to this project!

        ## How to Contribute

        1. Fork the repository
        2. Create a feature branch
        3. Make your changes
        4. Submit a pull request
      EOT
      commit_message = "Add contributing guidelines"
      commit_author  = "Terraform"
      commit_email   = "terraform@example.com"
    }
  ]

  # Webhooks
  webhooks = [
    {
      url          = "https://ci.example.com/webhook"
      events       = ["push", "pull_request", "release"]
      content_type = "json"
      secret       = "webhook_secret_token"
      insecure_ssl = false
    },
    {
      url          = "https://notifications.example.com/github"
      events       = ["issues", "issue_comment", "pull_request_review"]
      content_type = "json"
      insecure_ssl = false
    }
  ]

  # Repository rulesets
  rulesets = {
    "main-protection" = {
      target      = "branch"
      include     = ["main"]
      enforcement = "active"

      # Pull request requirements
      required_pr_approving_review_count   = 2
      required_pr_code_owner_review        = true
      required_pr_last_push_approval       = true
      required_pr_review_thread_resolution = true
      dismiss_pr_stale_reviews_on_push     = true

      # Status checks
      required_checks = [
        {
          context        = "build"
          integration_id = null
        },
        {
          context        = "test"
          integration_id = null
        },
        {
          context        = "lint"
          integration_id = null
        }
      ]

      # Code scanning
      required_code_scanning = {
        "CodeQL"           = "required:errors"
        "Security Scanner" = "required:errors_and_warnings"
      }

      # Additional protections
      required_linear_history = true
      required_signatures     = true
      forbidden_fast_forward  = true
    }

    "develop-protection" = {
      target      = "branch"
      include     = ["develop"]
      enforcement = "active"

      required_pr_approving_review_count = 1
      required_checks = [
        {
          context        = "build"
          integration_id = null
        },
        {
          context        = "test"
          integration_id = null
        }
      ]
    }

    "release-tags" = {
      target             = "tag"
      include            = ["v*"]
      enforcement        = "active"
      forbidden_deletion = true
      forbidden_update   = true

      # Commit requirements
      regex_commit_author_email = ".*@example\\.com$"
      required_signatures       = true
    }

    "feature-branches" = {
      target      = "branch"
      include     = ["feature/*"]
      enforcement = "evaluate"

      # Branch naming pattern validation
      regex_target = "^feature/[a-z0-9-]+$"

      # Basic PR requirements
      required_pr_approving_review_count = 1
    }
  }
}
