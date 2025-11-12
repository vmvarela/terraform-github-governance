# Advanced GitHub Rulesets Example
# Demonstrates all edge cases and complex ruleset configurations

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
  owner = var.github_org
}

# ============================================================================
# ADVANCED RULESETS EXAMPLE
#
# This example demonstrates ALL GitHub ruleset features and edge cases:
# - All enforcement levels (active, evaluate, disabled)
# - Complex ref patterns (~DEFAULT_BRANCH, ~ALL, wildcards, regex)
# - All bypass actor types (roles, teams, integrations, org admins)
# - Comprehensive PR rules (reviews, code owners, thread resolution)
# - All commit/author/committer email patterns
# - Branch and tag name patterns with all operators
# - Boolean rules (creation, deletion, update, force push, etc.)
# - Required deployments with environment gates
# - Code scanning requirements (CodeQL, custom thresholds)
# - Organization vs repository-specific rulesets
# - Pattern negation (NOT operators)
# - Special regex characters handling
# ============================================================================

module "github_org" {
  source = "../../"

  mode       = "organization"
  name       = "rulesets-advanced"
  github_org = var.github_org

  # ============================================================================
  # TEST REPOSITORIES - Different scenarios for ruleset testing
  # ============================================================================
  repositories = {
    "demo-main-protected" = {
      description = "Repository with main branch protection"
      visibility  = "public"
      topics      = ["demo", "main-protection"]
    }

    "demo-release-workflow" = {
      description = "Repository with release branch workflow"
      visibility  = "public"
      topics      = ["demo", "releases"]
    }

    "demo-monorepo" = {
      description = "Monorepo with complex branch patterns"
      visibility  = "public"
      topics      = ["demo", "monorepo"]
    }

    "demo-open-source" = {
      description = "Open source project with contributor rules"
      visibility  = "public"
      topics      = ["demo", "opensource"]
    }

    "demo-enterprise" = {
      description = "Enterprise repo with maximum security"
      visibility  = "private"
      topics      = ["demo", "enterprise", "security"]
    }
  }

  # ============================================================================
  # EDGE CASE 1: All Enforcement Levels
  # ============================================================================
  rulesets = {
    "edge-case-active-enforcement" = {
      enforcement = "active" # Blocks non-compliant actions
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
      }

      rules = {
        deletion = true # Prevent branch deletion
      }
    }

    "edge-case-evaluate-mode" = {
      enforcement = "evaluate" # Dry-run mode - logs but doesn't block
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/staging"]
          exclude = []
        }
      }

      rules = {
        required_linear_history = true
      }
    }

    "edge-case-disabled-ruleset" = {
      enforcement = "disabled" # Disabled but kept for future use
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/experimental"]
          exclude = []
        }
      }

      rules = {
        update = true # Would prevent force push if enabled
      }
    }

    # ============================================================================
    # EDGE CASE 2: Complex Ref Patterns
    # ============================================================================
    "edge-case-default-branch-pattern" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["~DEFAULT_BRANCH"] # Special pattern for default branch
          exclude = []
        }
      }

      rules = {
        deletion                = true
        required_linear_history = true
      }
    }

    "edge-case-all-branches-pattern" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["~ALL"]              # Special pattern for all branches
          exclude = ["refs/heads/wip/**"] # Exclude work-in-progress
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

    "edge-case-wildcard-patterns" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = [
            "refs/heads/feature/**", # All feature branches
            "refs/heads/bugfix/**",  # All bugfix branches
            "refs/heads/hotfix/**"   # All hotfix branches
          ]
          exclude = [
            "refs/heads/feature/poc-**", # Exclude proof-of-concept branches
            "refs/heads/bugfix/temp-**"  # Exclude temporary bugfix branches
          ]
        }
      }

      rules = {
        branch_name_pattern = {
          name     = "Branch Naming Convention"
          pattern  = "^(feature|bugfix|hotfix)/[A-Z]+-[0-9]+-[a-z0-9-]+$"
          operator = "regex"
          negate   = false
        }
      }
    }

    # ============================================================================
    # EDGE CASE 3: All Bypass Actor Types
    # ============================================================================
    "edge-case-all-bypass-actors" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/protected"]
          exclude = []
        }
      }

      # All types of bypass actors
      bypass_actors = {
        # Organization admins
        organization_admins = [true]

        # Repository roles
        repository_roles = ["admin", "maintain"]

        # Specific teams (use IDs or slugs)
        teams = ["platform-team", "security-team"]

        # GitHub Apps/Integrations (by ID)
        integrations = [] # Add integration IDs here: [12345, 67890]
      }

      rules = {
        deletion = true
        update   = true
      }
    }

    "edge-case-no-bypass-actors" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/production"]
          exclude = []
        }
      }

      # No bypass actors = Nobody can bypass, even org admins!
      bypass_actors = {
        organization_admins = [false]
      }

      rules = {
        deletion                = true
        update                  = true
        required_signatures     = true # GPG signatures required
        required_linear_history = true
      }
    }

    # ============================================================================
    # EDGE CASE 4: Comprehensive Pull Request Rules
    # ============================================================================
    "edge-case-pr-all-options" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
      }

      rules = {
        pull_request = {
          # Review requirements
          required_approving_review_count   = 2    # At least 2 approvals
          dismiss_stale_reviews_on_push     = true # New commits dismiss approvals
          require_code_owner_review         = true # CODEOWNERS must approve
          require_last_push_approval        = true # Final approval after last push
          required_review_thread_resolution = true # All threads must be resolved
        }
      }
    }

    "edge-case-pr-minimal" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/develop"]
          exclude = []
        }
      }

      rules = {
        pull_request = {
          required_approving_review_count = 1 # Just 1 approval
          # All other options default to false
        }
      }
    }

    # ============================================================================
    # EDGE CASE 5: Multiple Required Status Checks
    # ============================================================================
    "edge-case-status-checks-comprehensive" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
      }

      rules = {
        required_status_checks = {
          strict_required_status_checks_policy = true # Branch must be up to date

          required_checks = [
            # CI/CD checks
            { context = "ci/unit-tests" },
            { context = "ci/integration-tests" },
            { context = "ci/e2e-tests" },
            { context = "ci/lint" },
            { context = "ci/format" },

            # Security checks
            { context = "security/code-scanning" },
            { context = "security/dependency-review" },
            { context = "security/secret-scanning" },

            # Quality checks
            { context = "quality/sonarqube" },
            { context = "quality/coverage-threshold" },

            # Build checks
            { context = "build/docker-image" },
            { context = "build/artifacts" },

            # Integration-specific checks (optional integration_id)
            {
              context        = "custom-ci/build"
              integration_id = null # Null = any integration can provide this check
            }
          ]
        }
      }
    }

    "edge-case-status-checks-minimal" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/staging"]
          exclude = []
        }
      }

      rules = {
        required_status_checks = {
          strict_required_status_checks_policy = false # Branch can be behind
          required_checks = [
            { context = "ci/tests" } # Just one check
          ]
        }
      }
    }

    # ============================================================================
    # EDGE CASE 6: Commit/Author/Committer Email Patterns
    # ============================================================================
    "edge-case-commit-patterns" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
      }

      rules = {
        # Commit message pattern
        commit_message_pattern = {
          name     = "Jira Ticket Reference"
          pattern  = "\\[JIRA-[0-9]+\\]"
          operator = "regex"
          negate   = false
        }

        # Author email pattern
        commit_author_email_pattern = {
          name     = "Corporate Email Only"
          pattern  = "@company\\.com$"
          operator = "regex"
          negate   = false
        }

        # Committer email pattern (for signed commits)
        committer_email_pattern = {
          name     = "Verified Committers"
          pattern  = "@(company\\.com|trusted-partner\\.com)$"
          operator = "regex"
          negate   = false
        }
      }
    }

    "edge-case-email-patterns-with-negation" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/open-source"]
          exclude = []
        }
      }

      rules = {
        # Block commits from disposable email providers
        commit_author_email_pattern = {
          name     = "Block Disposable Emails"
          pattern  = "@(tempmail\\.com|throwaway\\.email|mailinator\\.com)$"
          operator = "regex"
          negate   = true # Negate = pattern must NOT match
        }
      }
    }

    # ============================================================================
    # EDGE CASE 7: Branch Name Patterns - All Operators
    # ============================================================================
    "edge-case-branch-starts-with" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/team-**"]
          exclude = []
        }
      }

      rules = {
        branch_name_pattern = {
          name     = "Team Prefix Required"
          pattern  = "team-[a-z]+-"
          operator = "starts_with"
          negate   = false
        }
      }
    }

    "edge-case-branch-ends-with" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/**-stable"]
          exclude = []
        }
      }

      rules = {
        branch_name_pattern = {
          name     = "Stable Suffix Required"
          pattern  = "-stable$"
          operator = "ends_with"
          negate   = false
        }
      }
    }

    "edge-case-branch-contains" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["~ALL"]
          exclude = []
        }
      }

      rules = {
        branch_name_pattern = {
          name     = "No Spaces in Branch Names"
          pattern  = " "
          operator = "contains"
          negate   = true # Must NOT contain spaces
        }
      }
    }

    "edge-case-branch-regex-complex" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/release/**"]
          exclude = []
        }
      }

      rules = {
        branch_name_pattern = {
          name     = "Semantic Versioning"
          pattern  = "^release/v[0-9]+\\.[0-9]+\\.[0-9]+(-[a-z0-9.]+)?(\\+[a-z0-9.]+)?$"
          operator = "regex"
          negate   = false
        }
      }
    }

    # ============================================================================
    # EDGE CASE 8: Tag Name Patterns - All Operators
    # ============================================================================
    "edge-case-tag-semver" = {
      enforcement = "active"
      target      = "tag"

      conditions = {
        ref_name = {
          include = ["refs/tags/v*"]
          exclude = []
        }
      }

      rules = {
        tag_name_pattern = {
          name     = "Semantic Versioning Tags"
          pattern  = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
          operator = "regex"
          negate   = false
        }
      }
    }

    "edge-case-tag-calver" = {
      enforcement = "active"
      target      = "tag"

      conditions = {
        ref_name = {
          include = ["refs/tags/20*"]
          exclude = []
        }
      }

      rules = {
        tag_name_pattern = {
          name     = "Calendar Versioning"
          pattern  = "^20[0-9]{2}\\.(0[1-9]|1[0-2])\\.(0[1-9]|[12][0-9]|3[01])\\.[0-9]+$"
          operator = "regex"
          negate   = false
        }

        deletion = true # Prevent tag deletion
        update   = true # Prevent tag force-push
      }
    }

    "edge-case-tag-prefix-enforcement" = {
      enforcement = "active"
      target      = "tag"

      conditions = {
        ref_name = {
          include = ["~ALL"]
          exclude = []
        }
      }

      rules = {
        tag_name_pattern = {
          name     = "Tags Must Start with v or r"
          pattern  = "^(v|r)"
          operator = "starts_with"
          negate   = false
        }
      }
    }

    # ============================================================================
    # EDGE CASE 9: All Boolean Rules
    # ============================================================================
    "edge-case-all-boolean-rules" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/locked"]
          exclude = []
        }
      }

      rules = {
        # Prevent all destructive operations
        creation = true # Prevent branch creation matching this pattern
        deletion = true # Prevent branch deletion
        update   = true # Prevent force push (non-fast-forward)

        # Require specific commit practices
        required_linear_history = true # No merge commits (squash/rebase only)
        required_signatures     = true # GPG signatures required

        # Pull request is separate, not a boolean
      }
    }

    "edge-case-creation-prevention" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/archive/**"]
          exclude = []
        }
      }

      rules = {
        creation = true # Prevent new archive branches from being created
      }
    }

    # ============================================================================
    # EDGE CASE 10: Required Deployments
    # ============================================================================
    "edge-case-deployment-gates" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
      }

      rules = {
        required_deployments = {
          required_deployment_environments = [
            "staging",
            "qa",
            "security-scan"
          ]
        }
      }
    }

    "edge-case-single-deployment" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/release/**"]
          exclude = []
        }
      }

      rules = {
        required_deployments = {
          required_deployment_environments = ["production"]
        }
      }
    }

    # ============================================================================
    # EDGE CASE 11: Code Scanning Requirements
    # ============================================================================
    "edge-case-code-scanning-high-severity" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
      }

      rules = {
        code_scanning = {
          # CodeQL analysis required
          required_analysis_tool = "CodeQL"

          # Block high or critical severity alerts
          security_alerts_threshold = "high_or_higher"

          # Specific alert types to check
          alerts_types = ["security", "quality"]
        }
      }
    }

    "edge-case-code-scanning-medium-severity" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/develop"]
          exclude = []
        }
      }

      rules = {
        code_scanning = {
          required_analysis_tool    = "CodeQL"
          security_alerts_threshold = "medium_or_higher"
          alerts_types              = ["security"]
        }
      }
    }

    "edge-case-code-scanning-all-severities" = {
      enforcement = "evaluate" # Dry-run for strictest setting
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/experimental"]
          exclude = []
        }
      }

      rules = {
        code_scanning = {
          required_analysis_tool    = "CodeQL"
          security_alerts_threshold = "all" # Block even low severity
          alerts_types              = ["security", "quality", "documentation"]
        }
      }
    }

    # ============================================================================
    # EDGE CASE 12: Repository-Specific Rulesets
    # ============================================================================
    # Note: Organization-level rulesets apply to ALL repos
    # Repository-specific rulesets would be defined in repositories map
    # This example shows the difference:

    "edge-case-org-level-global" = {
      enforcement = "active"
      target      = "branch"

      # No repository_conditions = applies to ALL repos in org
      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
      }

      rules = {
        deletion = true
      }
    }

    # ============================================================================
    # EDGE CASE 13: Maximum Complexity Ruleset
    # ============================================================================
    "edge-case-maximum-complexity" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/production"]
          exclude = []
        }
      }

      bypass_actors = {
        organization_admins = [false] # Nobody bypasses
      }

      rules = {
        # All protections enabled
        deletion                = true
        update                  = true
        creation                = false # Can create production branch
        required_linear_history = true
        required_signatures     = true

        # Strict PR requirements
        pull_request = {
          required_approving_review_count   = 3
          dismiss_stale_reviews_on_push     = true
          require_code_owner_review         = true
          require_last_push_approval        = true
          required_review_thread_resolution = true
        }

        # Comprehensive status checks
        required_status_checks = {
          strict_required_status_checks_policy = true
          required_checks = [
            { context = "ci/tests" },
            { context = "ci/lint" },
            { context = "security/scan" },
            { context = "quality/coverage" }
          ]
        }

        # Commit constraints
        commit_message_pattern = {
          name     = "Jira Reference Required"
          pattern  = "\\[JIRA-[0-9]+\\]"
          operator = "regex"
          negate   = false
        }

        commit_author_email_pattern = {
          name     = "Corporate Email"
          pattern  = "@company\\.com$"
          operator = "regex"
          negate   = false
        }

        # Deployment gate
        required_deployments = {
          required_deployment_environments = ["staging", "qa", "security-review"]
        }

        # Code scanning
        code_scanning = {
          required_analysis_tool    = "CodeQL"
          security_alerts_threshold = "high_or_higher"
          alerts_types              = ["security", "quality"]
        }
      }
    }

    # ============================================================================
    # EDGE CASE 14: Pattern Negation Examples
    # ============================================================================
    "edge-case-negated-patterns" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["~ALL"]
          exclude = []
        }
      }

      rules = {
        # Branch names must NOT contain uppercase
        branch_name_pattern = {
          name     = "No Uppercase Letters"
          pattern  = "[A-Z]"
          operator = "contains"
          negate   = true # Negate the match
        }

        # Commit messages must NOT be too short
        commit_message_pattern = {
          name     = "Minimum Length"
          pattern  = "^.{0,9}$" # 0-9 characters
          operator = "regex"
          negate   = true # Must NOT match (must be 10+ chars)
        }
      }
    }

    # ============================================================================
    # EDGE CASE 15: Special Regex Characters
    # ============================================================================
    "edge-case-special-regex-chars" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/versioned/**"]
          exclude = []
        }
      }

      rules = {
        branch_name_pattern = {
          name = "Complex Regex with Escaping"
          # Matches: versioned/v1.2.3-alpha.1+build.20240101
          pattern  = "^versioned/v[0-9]+\\.[0-9]+\\.[0-9]+(-[a-z0-9.]+)?(\\+[a-z0-9.]+)?$"
          operator = "regex"
          negate   = false
        }
      }
    }

    "edge-case-lookahead-lookbehind" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/feature/**"]
          exclude = []
        }
      }

      rules = {
        # Advanced regex: must start with feature/ and contain ticket number
        branch_name_pattern = {
          name     = "Feature with Ticket"
          pattern  = "^feature/(?=.*[A-Z]+-[0-9]+).*$" # Positive lookahead
          operator = "regex"
          negate   = false
        }
      }
    }

    # ============================================================================
    # EDGE CASE 16: Minimal Rulesets
    # ============================================================================
    "edge-case-minimal-branch-protection" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/minimal"]
          exclude = []
        }
      }

      # Minimal possible ruleset: just one rule
      rules = {
        deletion = true
      }
    }

    "edge-case-minimal-tag-protection" = {
      enforcement = "active"
      target      = "tag"

      conditions = {
        ref_name = {
          include = ["refs/tags/*"]
          exclude = []
        }
      }

      rules = {
        deletion = true
      }
    }

    # ============================================================================
    # EDGE CASE 17: Wildcard Exclusions
    # ============================================================================
    "edge-case-complex-exclusions" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          # Include all branches
          include = ["~ALL"]

          # But exclude multiple patterns
          exclude = [
            "refs/heads/wip/**",           # Work in progress
            "refs/heads/poc-**",           # Proof of concepts
            "refs/heads/*/temp",           # Temporary branches
            "refs/heads/user/*/sandbox/*", # User sandboxes
            "refs/heads/bot/**"            # Bot branches
          ]
        }
      }

      rules = {
        required_linear_history = true
      }
    }

    # ============================================================================
    # EDGE CASE 18: Multiple Rulesets on Same Branch
    # ============================================================================
    # GitHub evaluates ALL matching rulesets - they combine (not override)

    "edge-case-combine-1" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = []
        }
      }

      rules = {
        deletion = true
      }
    }

    "edge-case-combine-2" = {
      enforcement = "active"
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main"] # Same branch!
          exclude = []
        }
      }

      rules = {
        required_linear_history = true
      }
    }
    # Result: main branch has BOTH deletion protection AND linear history

    # ============================================================================
    # EDGE CASE 19: Empty Conditions (Don't Do This!)
    # ============================================================================
    # Note: This is an anti-pattern and would fail validation
    # Shown here for documentation purposes only

    # "edge-case-empty-conditions" = {
    #   enforcement = "active"
    #   target      = "branch"
    #
    #   conditions = {
    #     ref_name = {
    #       include = []  # INVALID: must have at least one pattern
    #       exclude = []
    #     }
    #   }
    #
    #   rules = {
    #     deletion = true
    #   }
    # }

    # ============================================================================
    # EDGE CASE 20: Conflicting Patterns (Don't Do This!)
    # ============================================================================
    # Note: This creates a ruleset that matches nothing
    # Shown here for documentation purposes only

    "edge-case-impossible-match" = {
      enforcement = "evaluate" # Use evaluate to avoid blocking
      target      = "branch"

      conditions = {
        ref_name = {
          include = ["refs/heads/main"]
          exclude = ["refs/heads/main"] # Excludes what we included!
        }
      }

      rules = {
        deletion = true
      }
    }
    # Result: This ruleset never matches any branch
  }
}
