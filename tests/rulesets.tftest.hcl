# Tests for ruleset resources (adapted from modules/repository)
# Tests now use the main module with composite keys for rulesets

mock_provider "github" {}
mock_provider "tls" {}
mock_provider "null" {}
mock_provider "local" {}

variables {
  mode       = "organization"
  name       = "test-org"
  github_org = "test-org"
  settings = {
    billing_email = "billing@test-org.com"
  }
}

# Test 1: Basic branch ruleset
run "basic_branch_ruleset" {
  command = plan

  variables {
    repositories = {
      "ruleset-repo" = {
        description = "Repository with basic ruleset"
        rulesets = {
          "protect-main" = {
            target  = "branch"
            include = ["main"]
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "ruleset-repo/") })) == 1
    error_message = "Should create 1 ruleset"
  }

  assert {
    condition     = github_repository_ruleset.repo["ruleset-repo/protect-main"].target == "branch"
    error_message = "Target should be 'branch'"
  }

  assert {
    condition     = github_repository_ruleset.repo["ruleset-repo/protect-main"].enforcement == "active"
    error_message = "Default enforcement should be 'active'"
  }
}

# Test 2: Ruleset with enforcement disabled
run "ruleset_enforcement_disabled" {
  command = plan

  variables {
    repositories = {
      "disabled-rule-repo" = {
        description = "Repository with disabled ruleset"
        rulesets = {
          "test-rule" = {
            target      = "branch"
            include     = ["main"]
            enforcement = "disabled"
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_ruleset.repo["disabled-rule-repo/test-rule"].enforcement == "disabled"
    error_message = "Enforcement should be 'disabled'"
  }
}

# Test 3: Tag ruleset
run "tag_ruleset" {
  command = plan

  variables {
    repositories = {
      "tag-repo" = {
        description = "Repository with tag protection"
        rulesets = {
          "protect-tags" = {
            target             = "tag"
            include            = ["v*"]
            forbidden_deletion = true
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_ruleset.repo["tag-repo/protect-tags"].target == "tag"
    error_message = "Target should be 'tag'"
  }

  assert {
    condition     = github_repository_ruleset.repo["tag-repo/protect-tags"].name == "protect-tags"
    error_message = "Ruleset name should match"
  }
}

# Test 4: Ruleset with bypass actors (roles)
run "ruleset_with_bypass_roles" {
  command = plan

  variables {
    repositories = {
      "bypass-repo" = {
        description = "Repository with bypass roles"
        rulesets = {
          "require-reviews" = {
            target       = "branch"
            include      = ["main"]
            bypass_roles = ["admin", "maintain"]
            bypass_mode  = "always"
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "bypass-repo/") })) == 1
    error_message = "Should create ruleset with bypass actors"
  }
}

# Test 5: Ruleset with bypass teams
run "ruleset_with_bypass_teams" {
  command = plan

  variables {
    repositories = {
      "team-bypass-repo" = {
        description = "Repository with team bypass"
        rulesets = {
          "team-bypass" = {
            target       = "branch"
            include      = ["main"]
            bypass_teams = [123456, 789012]
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "team-bypass-repo/") })) == 1
    error_message = "Should create ruleset with team bypass"
  }
}

# Test 6: Pull request rules
run "ruleset_pull_request_rules" {
  command = plan

  variables {
    repositories = {
      "pr-rules-repo" = {
        description = "Repository with PR rules"
        rulesets = {
          "pr-rules" = {
            target                               = "branch"
            include                              = ["main", "develop"]
            required_pr_approving_review_count   = 2
            required_pr_code_owner_review        = true
            required_pr_last_push_approval       = true
            dismiss_pr_stale_reviews_on_push     = true
            required_pr_review_thread_resolution = true
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "pr-rules-repo/") })) == 1
    error_message = "Should create ruleset with PR rules"
  }
}

# Test 7: Required status checks
run "ruleset_required_status_checks" {
  command = plan

  variables {
    repositories = {
      "checks-repo" = {
        description = "Repository with required checks"
        rulesets = {
          "ci-checks" = {
            target  = "branch"
            include = ["main"]
            required_checks = [
              "CI / test",
              "CI / lint",
              "Security / scan"
            ]
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "checks-repo/") })) == 1
    error_message = "Should create ruleset with required checks"
  }
}

# Test 8: Required code scanning
run "ruleset_required_code_scanning" {
  command = plan

  variables {
    repositories = {
      "scanning-repo" = {
        description = "Repository with code scanning rules"
        rulesets = {
          "security-scanning" = {
            target  = "branch"
            include = ["main"]
            required_code_scanning = {
              "CodeQL"    = "high:errors_and_warnings"
              "Snyk"      = "critical:errors"
              "SonarQube" = "none:warnings"
            }
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "scanning-repo/") })) == 1
    error_message = "Should create ruleset with code scanning"
  }
}

# Test 9: Commit message patterns
run "ruleset_commit_patterns" {
  command = plan

  variables {
    repositories = {
      "commit-repo" = {
        description = "Repository with commit patterns"
        rulesets = {
          "commit-rules" = {
            target                    = "branch"
            include                   = ["main"]
            regex_commit_message      = "^(feat|fix|docs|chore):"
            regex_commit_author_email = ".*@example\\.com$"
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "commit-repo/") })) == 1
    error_message = "Should create ruleset with commit patterns"
  }
}

# Test 10: Branch name pattern
run "ruleset_branch_name_pattern" {
  command = plan

  variables {
    repositories = {
      "branch-naming-repo" = {
        description = "Repository with branch naming pattern"
        rulesets = {
          "branch-naming" = {
            target       = "branch"
            include      = ["*"]
            regex_target = "^(feature|bugfix|hotfix)/.*"
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "branch-naming-repo/") })) == 1
    error_message = "Should create ruleset with branch naming pattern"
  }
}

# Test 11: Forbidden operations
run "ruleset_forbidden_operations" {
  command = plan

  variables {
    repositories = {
      "forbidden-repo" = {
        description = "Repository with forbidden operations"
        rulesets = {
          "main-protection" = {
            target                 = "branch"
            include                = ["main"]
            forbidden_creation     = true
            forbidden_deletion     = true
            forbidden_update       = true
            forbidden_fast_forward = true
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "forbidden-repo/") })) == 1
    error_message = "Should create ruleset with forbidden operations"
  }
}

# Test 12: Required deployments
run "ruleset_required_deployments" {
  command = plan

  variables {
    repositories = {
      "deployment-repo" = {
        description = "Repository with deployment gates"
        environments = {
          "staging"    = {}
          "production" = {}
        }
        rulesets = {
          "deployment-gates" = {
            target                           = "branch"
            include                          = ["main"]
            required_deployment_environments = ["staging", "production"]
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "deployment-repo/") })) == 1
    error_message = "Should create ruleset with deployment requirements"
  }
}

# Test 13: Required linear history
run "ruleset_linear_history" {
  command = plan

  variables {
    repositories = {
      "linear-repo" = {
        description = "Repository with linear history requirement"
        rulesets = {
          "linear-main" = {
            target                  = "branch"
            include                 = ["main"]
            required_linear_history = true
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "linear-repo/") })) == 1
    error_message = "Should create ruleset with linear history requirement"
  }
}

# Test 14: Required signatures
run "ruleset_required_signatures" {
  command = plan

  variables {
    repositories = {
      "signed-repo" = {
        description = "Repository with signature requirement"
        rulesets = {
          "signed-commits" = {
            target              = "branch"
            include             = ["main"]
            required_signatures = true
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "signed-repo/") })) == 1
    error_message = "Should create ruleset with signature requirement"
  }
}

# Test 15: Include/exclude patterns with special prefixes
run "ruleset_special_patterns" {
  command = plan

  variables {
    repositories = {
      "patterns-repo" = {
        description = "Repository with special patterns"
        rulesets = {
          "default-branch-protection" = {
            target  = "branch"
            include = ["~DEFAULT_BRANCH"]
            exclude = ["~ALL"]
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "patterns-repo/") })) == 1
    error_message = "Should create ruleset with special patterns"
  }
}

# Test 16: Multiple complex rulesets
run "multiple_complex_rulesets" {
  command = plan

  variables {
    repositories = {
      "multi-ruleset-repo" = {
        description = "Repository with multiple rulesets"
        rulesets = {
          "main-protection" = {
            target                             = "branch"
            include                            = ["main"]
            bypass_roles                       = ["admin"]
            required_pr_approving_review_count = 2
            required_checks                    = ["CI / test"]
            forbidden_deletion                 = true
          }
          "release-protection" = {
            target              = "branch"
            include             = ["release/*"]
            bypass_roles        = ["admin", "maintain"]
            required_signatures = true
            forbidden_deletion  = true
          }
          "tag-protection" = {
            target             = "tag"
            include            = ["v*"]
            forbidden_deletion = true
            forbidden_update   = true
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "multi-ruleset-repo/") })) == 3
    error_message = "Should create 3 rulesets"
  }
}

# Test 17: Bypass organization admin
run "ruleset_bypass_org_admin" {
  command = plan

  variables {
    repositories = {
      "org-admin-repo" = {
        description = "Repository with org admin bypass"
        rulesets = {
          "strict-main" = {
            target                    = "branch"
            include                   = ["main"]
            bypass_organization_admin = true
            bypass_mode               = "pull_request"
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_ruleset.repo : k => v if startswith(k, "org-admin-repo/") })) == 1
    error_message = "Should create ruleset with org admin bypass"
  }
}

# Test 18: Enforcement evaluate
run "ruleset_enforcement_evaluate" {
  command = plan

  variables {
    repositories = {
      "evaluate-repo" = {
        description = "Repository with evaluate enforcement"
        rulesets = {
          "test-rule" = {
            target      = "branch"
            include     = ["test/*"]
            enforcement = "evaluate"
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_ruleset.repo["evaluate-repo/test-rule"].enforcement == "evaluate"
    error_message = "Enforcement should be 'evaluate' for testing"
  }
}
