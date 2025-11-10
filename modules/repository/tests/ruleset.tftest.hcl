# Tests for ruleset module with mock providers

mock_provider "github" {}

variables {
  name       = "test-ruleset-repo"
  visibility = "public"
}

# Test 1: Basic ruleset for branches
run "basic_branch_ruleset" {
  command = plan

  variables {
    rulesets = {
      "protect-main" = {
        target  = "branch"
        include = ["main"]
      }
    }
  }

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create 1 ruleset"
  }

  assert {
    condition     = module.ruleset["protect-main"].ruleset.target == "branch"
    error_message = "Target should be 'branch'"
  }

  assert {
    condition     = module.ruleset["protect-main"].ruleset.enforcement == "active"
    error_message = "Default enforcement should be 'active'"
  }
}

# Test 2: Ruleset con enforcement disabled
run "ruleset_enforcement_disabled" {
  command = plan

  variables {
    rulesets = {
      "test-rule" = {
        target      = "branch"
        include     = ["main"]
        enforcement = "disabled"
      }
    }
  }

  assert {
    condition     = module.ruleset["test-rule"].ruleset.enforcement == "disabled"
    error_message = "Enforcement should be 'disabled'"
  }
}

# Test 3: Ruleset para tags
run "tag_ruleset" {
  command = plan

  variables {
    rulesets = {
      "protect-tags" = {
        target             = "tag"
        include            = ["v*"]
        forbidden_deletion = true
      }
    }
  }

  assert {
    condition     = module.ruleset["protect-tags"].ruleset.target == "tag"
    error_message = "Target should be 'tag'"
  }

  assert {
    condition     = module.ruleset["protect-tags"].ruleset.rules[0].deletion == true
    error_message = "Tag deletion should be forbidden"
  }
}

# Test 4: Ruleset con bypass actors (roles)
run "ruleset_with_bypass_roles" {
  command = plan

  variables {
    rulesets = {
      "require-reviews" = {
        target       = "branch"
        include      = ["main"]
        bypass_roles = ["admin", "maintain"]
        bypass_mode  = "always"
      }
    }
  }

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with bypass actors"
  }
}

# Test 5: Ruleset con bypass teams
run "ruleset_with_bypass_teams" {
  command = plan

  variables {
    rulesets = {
      "team-bypass" = {
        target       = "branch"
        include      = ["main"]
        bypass_teams = [123456, 789012]
      }
    }
  }

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with team bypass"
  }
}

# Test 6: Pull request rules
run "ruleset_pull_request_rules" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with PR rules"
  }
}

# Test 7: Required status checks
run "ruleset_required_status_checks" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with required checks"
  }
}

# Test 8: Required code scanning
run "ruleset_required_code_scanning" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with code scanning"
  }
}

# Test 9: Commit message patterns
run "ruleset_commit_patterns" {
  command = plan

  variables {
    rulesets = {
      "commit-rules" = {
        target                    = "branch"
        include                   = ["main"]
        regex_commit_message      = "^(feat|fix|docs|chore):"
        regex_commit_author_email = ".*@example\\.com$"
      }
    }
  }

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with commit patterns"
  }
}

# Test 10: Branch name pattern
run "ruleset_branch_name_pattern" {
  command = plan

  variables {
    rulesets = {
      "branch-naming" = {
        target       = "branch"
        include      = ["*"]
        regex_target = "^(feature|bugfix|hotfix)/.*"
      }
    }
  }

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with branch naming pattern"
  }
}

# Test 11: Forbidden operations
run "ruleset_forbidden_operations" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with forbidden operations"
  }
}

# Test 12: Required deployments
run "ruleset_required_deployments" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with deployment requirements"
  }
}

# Test 13: Required linear history
run "ruleset_linear_history" {
  command = plan

  variables {
    rulesets = {
      "linear-main" = {
        target                  = "branch"
        include                 = ["main"]
        required_linear_history = true
      }
    }
  }

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with linear history requirement"
  }
}

# Test 14: Required signatures
run "ruleset_required_signatures" {
  command = plan

  variables {
    rulesets = {
      "signed-commits" = {
        target              = "branch"
        include             = ["main"]
        required_signatures = true
      }
    }
  }

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with signature requirement"
  }
}

# Test 15: Include/exclude patterns con ~ prefix
run "ruleset_special_patterns" {
  command = plan

  variables {
    rulesets = {
      "default-branch-protection" = {
        target  = "branch"
        include = ["~DEFAULT_BRANCH"]
        exclude = ["~ALL"]
      }
    }
  }

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with special patterns"
  }
}

# Test 16: Multiple complex rulesets
run "multiple_complex_rulesets" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.ruleset)) == 3
    error_message = "Should create 3 rulesets"
  }
}

# Test 17: Bypass organization admin
run "ruleset_bypass_org_admin" {
  command = plan

  variables {
    rulesets = {
      "strict-main" = {
        target                    = "branch"
        include                   = ["main"]
        bypass_organization_admin = true
        bypass_mode               = "pull_request"
      }
    }
  }

  assert {
    condition     = length(keys(module.ruleset)) == 1
    error_message = "Should create ruleset with org admin bypass"
  }
}

# Test 18: Enforcement evaluate
run "ruleset_enforcement_evaluate" {
  command = plan

  variables {
    rulesets = {
      "test-rule" = {
        target      = "branch"
        include     = ["test/*"]
        enforcement = "evaluate"
      }
    }
  }

  assert {
    condition     = module.ruleset["test-rule"].ruleset.enforcement == "evaluate"
    error_message = "Enforcement should be 'evaluate' for testing"
  }
}
