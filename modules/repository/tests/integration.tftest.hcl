# Complete integration test - Simulates a real repository with all features

mock_provider "github" {}
mock_provider "tls" {}
mock_provider "null" {}
mock_provider "local" {}

# Test 1: Complete repository with all features
run "complete_repository_integration" {
  command = plan

  variables {
    name         = "complete-terraform-project"
    description  = "Complete Terraform project with all features"
    visibility   = "public"
    homepage     = "https://example.com"
    has_issues   = true
    has_projects = true
    has_wiki     = true
    topics       = ["terraform", "github", "automation", "infrastructure"]

    # Merge strategies
    allow_merge_commit          = true
    allow_squash_merge          = true
    allow_rebase_merge          = false
    allow_auto_merge            = true
    delete_branch_on_merge      = true
    squash_merge_commit_title   = "PR_TITLE"
    squash_merge_commit_message = "COMMIT_MESSAGES"

    # Security
    enable_vulnerability_alerts        = true
    enable_dependabot_security_updates = true
    web_commit_signoff_required        = true

    # GitHub Actions
    enable_actions           = true
    actions_allowed_policy   = "selected"
    actions_allowed_github   = true
    actions_allowed_verified = true
    actions_allowed_patterns = ["actions/*", "hashicorp/*"]
    actions_access_level     = "organization"

    # Branches
    default_branch = "main"
    branches = {
      "develop" = "main"
      "staging" = "main"
    }

    # Secrets and Variables
    secrets = {
      "AWS_ACCESS_KEY_ID"     = "AKIA..."
      "AWS_SECRET_ACCESS_KEY" = "secret..."
      "DOCKERHUB_TOKEN"       = "token..."
    }
    variables = {
      "AWS_REGION"   = "us-east-1"
      "ENVIRONMENT"  = "production"
      "PROJECT_NAME" = "terraform-project"
    }
    dependabot_copy_secrets = true

    # Deploy Keys
    deploy_keys = {
      "ci-cd-deploy-key" = {
        public_key = null
        read_only  = false
      }
      "readonly-key" = {
        public_key = null
        read_only  = true
      }
    }

    # Issue Labels
    issue_labels = {
      "bug"              = "Something isn't working"
      "enhancement"      = "New feature or request"
      "documentation"    = "Documentation improvements"
      "good-first-issue" = "Good for newcomers"
      "help-wanted"      = "Extra attention is needed"
    }
    issue_labels_colors = {
      "bug"           = "d73a4a"
      "enhancement"   = "a2eeef"
      "documentation" = "0075ca"
    }

    # Autolink References
    autolink_references = {
      "JIRA-"   = "https://jira.example.com/browse/<num>"
      "TICKET-" = "https://tickets.example.com/issue/<num>"
    }

    # Collaborators
    teams = {
      "123456" = "admin"
      "789012" = "push"
    }
    users = {
      "developer1"  = "push"
      "developer2"  = "push"
      "maintainer1" = "maintain"
    }

    # Environments
    environments = {
      "development" = {
        can_admins_bypass = true
        variables = {
          "ENVIRONMENT" = "dev"
          "DEBUG"       = "true"
        }
        secrets = {
          "API_KEY" = "dev-key"
        }
      }
      "staging" = {
        wait_timer         = 15
        can_admins_bypass  = false
        reviewers_teams    = [123456]
        protected_branches = true
        variables = {
          "ENVIRONMENT" = "staging"
        }
      }
      "production" = {
        wait_timer             = 30
        can_admins_bypass      = false
        prevent_self_review    = true
        reviewers_teams        = [123456]
        reviewers_users        = [111111]
        custom_branch_policies = ["main"]
        variables = {
          "ENVIRONMENT" = "production"
          "DEBUG"       = "false"
        }
        secrets = {
          "API_KEY"      = "prod-key"
          "DATABASE_URL" = "prod-db-url"
        }
      }
    }

    # Rulesets
    rulesets = {
      "main-protection" = {
        target                             = "branch"
        include                            = ["main"]
        bypass_roles                       = ["admin"]
        forbidden_deletion                 = true
        forbidden_fast_forward             = true
        required_pr_approving_review_count = 2
        required_pr_code_owner_review      = true
        required_pr_last_push_approval     = true
        dismiss_pr_stale_reviews_on_push   = true
        required_linear_history            = true
        required_signatures                = true
        required_checks = [
          "CI / test",
          "CI / lint",
          "Security / scan"
        ]
        required_code_scanning = {
          "CodeQL" = "high:errors"
        }
      }
      "release-protection" = {
        target              = "branch"
        include             = ["release/*"]
        bypass_roles        = ["admin"]
        forbidden_deletion  = true
        required_signatures = true
      }
      "tag-protection" = {
        target             = "tag"
        include            = ["v*"]
        forbidden_deletion = true
        forbidden_update   = true
      }
    }

    # Files
    files = [
      {
        file           = "README.md"
        content        = <<-EOT
          # Complete Terraform Project

          This is a complete example project.

          ## Features
          - Full GitHub repository management
          - Branch protection
          - Environment management
          - CI/CD integration
        EOT
        commit_message = "docs: Initialize README"
      },
      {
        file           = ".gitignore"
        content        = <<-EOT
          # Terraform
          *.tfstate
          *.tfstate.*
          .terraform/
          .terraform.lock.hcl
          *.tfvars

          # IDE
          .idea/
          .vscode/
        EOT
        commit_message = "chore: Add .gitignore"
      },
      {
        file           = "CONTRIBUTING.md"
        content        = "# Contributing Guide\n\nPlease read before contributing."
        commit_message = "docs: Add contributing guide"
      }
    ]

    # Webhooks
    webhooks = [
      {
        url          = "https://ci.example.com/github"
        events       = ["push", "pull_request", "pull_request_review"]
        content_type = "json"
        secret       = "ci-webhook-secret"
      },
      {
        url          = "https://monitoring.example.com/events"
        events       = ["issues", "issue_comment"]
        content_type = "json"
      }
    ]
  }

  # Assertions para el repositorio principal
  assert {
    condition     = github_repository.this.name == "complete-terraform-project"
    error_message = "Repository name should match"
  }

  assert {
    condition     = github_repository.this.visibility == "public"
    error_message = "Repository should be public"
  }

  assert {
    condition     = length(github_repository.this.topics) == 4
    error_message = "Should have 4 topics"
  }

  # Assertions para branches
  assert {
    condition     = github_branch_default.this[0].branch == "main"
    error_message = "Default branch should be main"
  }

  assert {
    condition     = length(github_branch.this) == 2
    error_message = "Should create 2 additional branches"
  }

  # Assertions para GitHub Actions
  assert {
    condition     = github_actions_repository_permissions.this[0].enabled == true
    error_message = "Actions should be enabled"
  }

  assert {
    condition     = github_actions_repository_access_level.this[0].access_level == "organization"
    error_message = "Actions access level should be organization"
  }

  # Assertions para secrets y variables
  assert {
    condition     = length(keys(github_actions_secret.plaintext)) == 3
    error_message = "Should create 3 actions secrets"
  }

  assert {
    condition     = length(keys(github_actions_variable.this)) == 3
    error_message = "Should create 3 actions variables"
  }

  # Note: dependabot_copy_secrets evaluation requires full apply
  # Skipping this assertion for plan-only tests

  # Assertions para deploy keys
  assert {
    condition     = length(github_repository_deploy_key.this) == 2
    error_message = "Should create 2 deploy keys"
  }

  # Assertions para issue labels
  assert {
    condition     = length(github_issue_labels.this) == 1
    error_message = "Should create issue labels resource"
  }

  # Assertions para autolink references
  assert {
    condition     = length(github_repository_autolink_reference.this) == 2
    error_message = "Should create 2 autolink references"
  }

  # Assertions para collaborators
  assert {
    condition     = length(github_repository_collaborators.this[0].team) == 2
    error_message = "Should configure 2 teams"
  }

  assert {
    condition     = length(github_repository_collaborators.this[0].user) == 3
    error_message = "Should configure 3 users"
  }

  # Assertions para environments
  assert {
    condition     = length(module.environment) == 3
    error_message = "Should create 3 environments"
  }

  assert {
    condition     = module.environment["production"].environment.wait_timer == 30
    error_message = "Production should have 30 min wait timer"
  }

  assert {
    condition     = module.environment["production"].environment.prevent_self_review == true
    error_message = "Production should prevent self review"
  }

  # Assertions para rulesets
  assert {
    condition     = length(keys(module.ruleset)) == 3
    error_message = "Should create 3 rulesets"
  }

  # Assertions para files
  assert {
    condition     = length(keys(module.file)) == 3
    error_message = "Should create 3 files"
  }

  # Assertions para webhooks
  assert {
    condition     = length(keys(module.webhook)) == 2
    error_message = "Should create 2 webhooks"
  }

  # Assertions para seguridad
  assert {
    condition     = github_repository.this.vulnerability_alerts == true
    error_message = "Vulnerability alerts should be enabled"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.this[0].enabled == true
    error_message = "Dependabot security updates should be enabled"
  }

  # Assertions para merge strategies
  assert {
    condition     = github_repository.this.delete_branch_on_merge == true
    error_message = "Should delete branch on merge"
  }

  assert {
    condition     = github_repository.this.allow_auto_merge == true
    error_message = "Should allow auto merge"
  }
}

# Test 2: Repositorio privado empresarial completo
run "enterprise_private_repository" {
  command = plan

  variables {
    name                                   = "enterprise-backend-api"
    description                            = "Enterprise backend API - Private"
    visibility                             = "private"
    enable_advanced_security               = true
    enable_secret_scanning                 = true
    enable_secret_scanning_push_protection = true
    web_commit_signoff_required            = true

    default_branch = "main"

    # Strict merge policies
    allow_merge_commit     = false
    allow_squash_merge     = true
    allow_rebase_merge     = false
    delete_branch_on_merge = true

    # Environments con strict controls
    environments = {
      "production" = {
        wait_timer             = 60
        can_admins_bypass      = false
        prevent_self_review    = true
        reviewers_teams        = [123456, 789012]
        custom_branch_policies = ["main"]
        secrets = {
          "API_KEY" = "prod-secret"
        }
      }
    }

    # Strict branch protection
    rulesets = {
      "main-strict" = {
        target                             = "branch"
        include                            = ["main"]
        bypass_organization_admin          = true
        forbidden_creation                 = true
        forbidden_deletion                 = true
        forbidden_update                   = true
        forbidden_fast_forward             = true
        required_pr_approving_review_count = 3
        required_pr_code_owner_review      = true
        required_pr_last_push_approval     = true
        required_linear_history            = true
        required_signatures                = true
        required_code_scanning = {
          "CodeQL" = "high:errors"
          "Snyk"   = "critical:errors"
        }
      }
    }
  }

  assert {
    condition     = github_repository.this.visibility == "private"
    error_message = "Repository should be private"
  }

  assert {
    condition     = github_repository.this.allow_merge_commit == false
    error_message = "Merge commits should be disabled"
  }

  assert {
    condition     = module.environment["production"].environment.wait_timer == 60
    error_message = "Production should have 60 min wait timer"
  }

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create strict ruleset"
  }
}

# Test 3: Open source repository with community configuration
run "open_source_community_repository" {
  command = plan

  variables {
    name        = "awesome-open-source-project"
    description = "An awesome open source project"
    visibility  = "public"
    is_template = true
    has_issues  = true
    has_wiki    = true
    topics      = ["opensource", "community", "terraform", "good-first-issue"]

    issue_labels = {
      "good-first-issue" = "Good for newcomers"
      "help-wanted"      = "Extra attention is needed"
      "documentation"    = "Documentation improvements"
      "bug"              = "Something isn't working"
      "enhancement"      = "New feature or request"
      "question"         = "Further information is requested"
      "wontfix"          = "This will not be worked on"
    }

    files = [
      {
        file    = "README.md"
        content = "# Awesome Open Source Project\n\nWelcome contributors!"
      },
      {
        file    = "CONTRIBUTING.md"
        content = "# Contributing\n\nThank you for your interest!"
      },
      {
        file    = "CODE_OF_CONDUCT.md"
        content = "# Code of Conduct\n\nBe respectful."
      },
      {
        file    = "LICENSE"
        content = "MIT License"
      }
    ]

    rulesets = {
      "main-protection" = {
        target                             = "branch"
        include                            = ["main"]
        required_pr_approving_review_count = 1
        required_checks                    = ["CI / test"]
      }
    }
  }

  assert {
    condition     = github_repository.this.is_template == true
    error_message = "Should be a template repository"
  }

  assert {
    condition     = length(github_issue_labels.this) == 1
    error_message = "Should have community labels"
  }

  assert {
    condition     = length(keys(module.file)) == 4
    error_message = "Should have community documentation files"
  }
}

# Test 4: Monorepo with multiple rulesets and environments
run "monorepo_multiple_rulesets" {
  command = plan

  variables {
    name       = "company-monorepo"
    visibility = "private"

    branches = {
      "develop"    = "main"
      "staging"    = "main"
      "frontend/*" = "develop"
      "backend/*"  = "develop"
    }

    environments = {
      "dev"        = {}
      "staging"    = { wait_timer = 15 }
      "production" = { wait_timer = 30, prevent_self_review = true }
    }

    rulesets = {
      "main-protection" = {
        target                             = "branch"
        include                            = ["main"]
        required_pr_approving_review_count = 2
      }
      "develop-protection" = {
        target                             = "branch"
        include                            = ["develop"]
        required_pr_approving_review_count = 1
      }
      "feature-naming" = {
        target       = "branch"
        include      = ["feature/*"]
        regex_target = "^feature/[A-Z]+-[0-9]+-.*"
      }
      "release-tags" = {
        target             = "tag"
        include            = ["v*"]
        forbidden_deletion = true
      }
    }
  }

  assert {
    condition     = length(keys(module.environment)) == 3
    error_message = "Should create 3 environments"
  }

  assert {
    condition     = length(keys(module.ruleset)) == 4
    error_message = "Should create 4 rulesets"
  }
}
