# Large Scale Organization Example
# Demonstrates module usage with 100+ repositories across multiple teams

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
  owner = var.organization_name
  token = var.github_token
  # Use GitHub App authentication for production
  # app_auth {
  #   id              = var.github_app_id
  #   installation_id = var.github_app_installation_id
  #   pem_file        = var.github_app_pem_file
  # }
}

# ============================================================================
# LARGE SCALE ORGANIZATION EXAMPLE
# 
# This example demonstrates managing a large organization with:
# - 100+ repositories across multiple teams
# - Consistent security policies via settings
# - Team-based access control
# - Organization-wide rulesets for compliance
# ============================================================================

module "github_org" {
  source = "../../"

  mode          = "organization"
  name          = var.organization_name
  billing_email = var.billing_email

  # ============================================================================
  # GLOBAL DEFAULTS - Applied to all repositories
  # ============================================================================
  defaults = {
    visibility                  = "private"
    has_issues                  = true
    has_discussions             = false
    has_wiki                    = false
    delete_branch_on_merge      = true
    allow_merge_commit          = false
    allow_squash_merge          = true
    allow_rebase_merge          = false
    squash_merge_commit_title   = "PR_TITLE"
    squash_merge_commit_message = "COMMIT_MESSAGES"
  }

  # ============================================================================
  # ORGANIZATION SETTINGS - Security and compliance policies
  # ============================================================================
  settings = {
    # Security features (enforced across all repos)
    enable_vulnerability_alerts            = true
    enable_dependabot_security_updates     = true
    enable_secret_scanning                 = true
    enable_secret_scanning_push_protection = true

    # Standard issue labels for all repositories
    issue_labels = {
      "bug"           = "d73a4a" # red
      "enhancement"   = "a2eeef" # blue
      "documentation" = "0075ca" # dark blue
      "security"      = "ee0701" # bright red
      "performance"   = "fbca04" # yellow
      "tech-debt"     = "d876e3" # purple
    }

    # Common secrets for all repositories
    secrets_encrypted = {
      SLACK_WEBHOOK_URL  = var.slack_webhook_encrypted
      SONARQUBE_TOKEN    = var.sonarqube_token_encrypted
      NPM_REGISTRY_TOKEN = var.npm_token_encrypted
    }

    # Organization-wide teams (access control)
    teams = {
      "platform-team" = "admin"    # Full access for platform engineers
      "security-team" = "maintain" # Can manage settings but not delete
      "developers"    = "push"     # Standard developer access
      "contractors"   = "pull"     # Read-only for external contractors
    }
  }

  # ============================================================================
  # REPOSITORIES - 100+ repositories organized by domain
  # ============================================================================
  repositories = merge(
    # -------------------------------------------------------------------------
    # Backend Services (40 microservices)
    # -------------------------------------------------------------------------
    { for i in range(40) :
      "backend-service-${format("%03d", i)}" => {
        description = "Backend microservice ${i} - ${lookup(local.service_domains, i % 8, "general")}"
        visibility  = "private"

        topics = [
          "backend",
          "microservice",
          local.service_domains[i % 8],
          "kotlin",
          "spring-boot"
        ]

        # Service-specific configuration
        has_issues = true

        environments = {
          production = {
            wait_timer        = 300
            can_admins_bypass = false
            reviewers_teams   = ["platform-team", "security-team"]
            deployment_branch_policy = {
              protected_branches     = true
              custom_branch_policies = false
            }
          }
          staging = {
            wait_timer        = 60
            can_admins_bypass = true
          }
          development = {
            can_admins_bypass = true
          }
        }

        # Additional team access for domain-specific teams
        teams = {
          "team-${local.service_domains[i % 8]}" = "push"
        }
      }
    },

    # -------------------------------------------------------------------------
    # Frontend Applications (20 apps)
    # -------------------------------------------------------------------------
    { for i in range(20) :
      "frontend-app-${format("%02d", i)}" => {
        description = "Frontend application ${i} - ${lookup(local.frontend_types, i % 4, "web")}"
        visibility  = "private"

        topics = [
          "frontend",
          local.frontend_types[i % 4],
          "react",
          "typescript"
        ]

        has_discussions = true # Enable discussions for user-facing apps

        environments = {
          production = {
            wait_timer      = 300
            reviewers_teams = ["platform-team"]
            deployment_branch_policy = {
              protected_branches = true
            }
          }
        }

        teams = {
          "frontend-team" = "push"
        }
      }
    },

    # -------------------------------------------------------------------------
    # Infrastructure & Tools (15 repositories)
    # -------------------------------------------------------------------------
    { for i in range(15) :
      "infra-${local.infra_repos[i]}" => {
        description = "Infrastructure: ${local.infra_repos[i]}"
        visibility  = "private"

        topics = [
          "infrastructure",
          "terraform",
          "automation"
        ]

        teams = {
          "platform-team" = "admin"
          "sre-team"      = "maintain"
        }

        # Infrastructure repos need strict protection
        enable_vulnerability_alerts        = true
        enable_dependabot_security_updates = true
      }
    },

    # -------------------------------------------------------------------------
    # Data & Analytics (15 repositories)
    # -------------------------------------------------------------------------
    { for i in range(15) :
      "data-${local.data_repos[i]}" => {
        description = "Data pipeline: ${local.data_repos[i]}"
        visibility  = "private"

        topics = [
          "data",
          "analytics",
          "python",
          "spark"
        ]

        teams = {
          "data-team"      = "admin"
          "analytics-team" = "push"
        }
      }
    },

    # -------------------------------------------------------------------------
    # Mobile Applications (10 repositories)
    # -------------------------------------------------------------------------
    { for i in range(10) :
      "mobile-${local.mobile_apps[i]}" => {
        description = "Mobile app: ${local.mobile_apps[i]}"
        visibility  = "private"

        topics = [
          "mobile",
          i < 5 ? "ios" : "android",
          i < 5 ? "swift" : "kotlin"
        ]

        teams = {
          "mobile-team" = "push"
        }

        environments = {
          production = {
            wait_timer      = 600 # 10 minutes for mobile releases
            reviewers_teams = ["mobile-team", "qa-team"]
          }
        }
      }
    },

    # -------------------------------------------------------------------------
    # Documentation & Public Repos (5 repositories)
    # -------------------------------------------------------------------------
    {
      "public-docs" = {
        description = "Public documentation and guides"
        visibility  = "public"

        topics = ["documentation", "guides", "public"]

        has_wiki        = true
        has_discussions = true

        teams = {
          "documentation-team" = "maintain"
        }
      }

      "open-source-lib" = {
        description = "Open source library maintained by the company"
        visibility  = "public"

        topics = ["opensource", "library", "typescript"]

        has_issues      = true
        has_discussions = true

        teams = {
          "opensource-team" = "maintain"
        }
      }

      ".github" = {
        description = "Organization profile and templates"
        visibility  = "public"

        topics = ["meta", "templates"]
      }

      "security-policy" = {
        description = "Security policies and vulnerability disclosure"
        visibility  = "public"

        topics = ["security", "policy"]

        teams = {
          "security-team" = "admin"
        }
      }

      "engineering-handbook" = {
        description = "Internal engineering handbook and best practices"
        visibility  = "private"

        topics = ["documentation", "handbook", "bestpractices"]

        has_wiki = true

        teams = {
          "platform-team" = "maintain"
        }
      }
    }
  )

  # ============================================================================
  # ORGANIZATION-WIDE RULESETS - Compliance and security
  # ============================================================================
  rulesets = {
    # Protect main branches across all repositories
    "main-branch-protection" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["~DEFAULT_BRANCH"]
          exclude = []
        }
      }

      bypass_actors = {
        teams               = ["platform-team"]
        organization_admins = [true]
      }

      rules = {
        deletion                = true  # Prevent deletion
        required_linear_history = true  # Enforce rebase/squash
        required_signatures     = false # GPG signatures (optional)

        pull_request = {
          required_approving_review_count   = 1
          dismiss_stale_reviews_on_push     = true
          require_code_owner_review         = false
          require_last_push_approval        = false
          required_review_thread_resolution = true
        }

        required_status_checks = {
          strict_required_status_checks_policy = true
          required_checks = [
            { context = "ci/tests" },
            { context = "ci/lint" },
            { context = "security/scan" }
          ]
        }
      }
    }

    # Enforce conventional commits
    "conventional-commits" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["~ALL"]
          exclude = []
        }
      }

      rules = {
        commit_message_pattern = {
          name     = "Conventional Commits"
          pattern  = "^(feat|fix|docs|style|refactor|perf|test|chore)(\\([a-z0-9-]+\\))?: .{1,100}"
          operator = "regex"
          negate   = false
        }
      }
    }

    # Protect release branches
    "release-branch-protection" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/release/**"]
          exclude = []
        }
      }

      rules = {
        deletion = true
        update   = true # Prevent force push

        pull_request = {
          required_approving_review_count = 2 # More strict for releases
          require_code_owner_review       = true
        }
      }
    }

    # Tag protection for semantic versioning
    "semver-tags" = {
      enforcement = "active"
      target      = "tag"

      conditions = {
        ref_name = {
          include = ["refs/tags/*"]
          exclude = []
        }
      }

      bypass_actors = {
        teams = ["platform-team"]
      }

      rules = {
        deletion = true
        update   = true

        tag_name_pattern = {
          name     = "Semantic Versioning"
          pattern  = "^v[0-9]+\\.[0-9]+\\.[0-9]+(-[a-z0-9.]+)?$"
          operator = "regex"
          negate   = false
        }
      }
    }
  }

  # ============================================================================
  # GITHUB ACTIONS - Runner groups for different environments
  # ============================================================================
  runner_groups = {
    "production-runners" = {
      visibility                 = "selected"
      allows_public_repositories = false

      # Only production services can use these runners
      repositories = [
        for i in range(40) : "backend-service-${format("%03d", i)}"
      ]
    }

    "general-runners" = {
      visibility                 = "all"
      allows_public_repositories = false
    }
  }
}

# ============================================================================
# LOCALS - Helper mappings for repository organization
# ============================================================================
locals {
  # Service domain mapping (microservices by domain)
  service_domains = {
    0 = "auth"
    1 = "billing"
    2 = "users"
    3 = "orders"
    4 = "inventory"
    5 = "shipping"
    6 = "notifications"
    7 = "analytics"
  }

  # Frontend application types
  frontend_types = {
    0 = "web-app"
    1 = "admin-portal"
    2 = "customer-portal"
    3 = "internal-tools"
  }

  # Infrastructure repository names
  infra_repos = [
    "terraform-aws",
    "terraform-gcp",
    "kubernetes-manifests",
    "helm-charts",
    "ansible-playbooks",
    "docker-images",
    "ci-cd-templates",
    "monitoring-config",
    "logging-config",
    "security-policies",
    "backup-scripts",
    "disaster-recovery",
    "network-config",
    "database-migrations",
    "infrastructure-tests"
  ]

  # Data repository names
  data_repos = [
    "etl-pipeline-1",
    "etl-pipeline-2",
    "data-warehouse",
    "analytics-dashboards",
    "ml-models",
    "data-quality-checks",
    "streaming-processor",
    "batch-jobs",
    "data-lake-ingestion",
    "feature-store",
    "data-catalog",
    "dbt-models",
    "airflow-dags",
    "spark-jobs",
    "data-api"
  ]

  # Mobile application names
  mobile_apps = [
    "ios-main",
    "ios-tablet",
    "ios-watch",
    "ios-widgets",
    "ios-intents",
    "android-main",
    "android-tablet",
    "android-wear",
    "android-tv",
    "flutter-shared"
  ]
}

# ============================================================================
# OUTPUTS
# ============================================================================
output "summary" {
  description = "Organization summary"
  value = {
    organization          = var.github_org
    total_repositories    = module.github_org.repositories_summary.total
    by_visibility         = module.github_org.repositories_summary.by_visibility
    security_posture      = module.github_org.repositories_security_posture
    runner_groups         = length(module.github_org.runner_group_ids)
    organization_rulesets = length(module.github_org.ruleset_ids)
  }
}

output "repositories_by_team" {
  description = "Repositories grouped by primary team"
  value = {
    backend  = length([for k, r in module.github_org.repositories : k if can(regex("^backend-", k))])
    frontend = length([for k, r in module.github_org.repositories : k if can(regex("^frontend-", k))])
    infra    = length([for k, r in module.github_org.repositories : k if can(regex("^infra-", k))])
    data     = length([for k, r in module.github_org.repositories : k if can(regex("^data-", k))])
    mobile   = length([for k, r in module.github_org.repositories : k if can(regex("^mobile-", k))])
    public   = module.github_org.repositories_summary.by_visibility.public
  }
}
