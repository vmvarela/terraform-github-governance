# Tests for environment resources (adapted from modules/repository)
# Tests now use the main module with composite keys for environments

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

# Test 1: Basic environment without configuration
run "basic_environment" {
  command = plan

  variables {
    repositories = {
      "env-repo" = {
        description = "Repository with basic environment"
        environments = {
          "production" = {}
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_environment.repo : k => v if startswith(k, "env-repo/") })) == 1
    error_message = "Should create 1 environment"
  }

  assert {
    condition     = github_repository_environment.repo["env-repo/production"].environment == "production"
    error_message = "Environment name should be 'production'"
  }
}

# Test 2: Environment with reviewers
run "environment_with_reviewers" {
  command = plan

  variables {
    repositories = {
      "reviewers-repo" = {
        description = "Repository with reviewers"
        environments = {
          "production" = {
            reviewers_teams = [123456, 789012]
            reviewers_users = [111111, 222222]
          }
        }
      }
    }
  }

  assert {
    condition     = length(github_repository_environment.repo["reviewers-repo/production"].reviewers[0].teams) == 2
    error_message = "Should have 2 team reviewers"
  }

  assert {
    condition     = length(github_repository_environment.repo["reviewers-repo/production"].reviewers[0].users) == 2
    error_message = "Should have 2 user reviewers"
  }
}

# Test 3: Environment with wait timer
run "environment_with_wait_timer" {
  command = plan

  variables {
    repositories = {
      "timer-repo" = {
        description = "Repository with wait timer"
        environments = {
          "staging" = {
            wait_timer = 30
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_environment.repo["timer-repo/staging"].wait_timer == 30
    error_message = "Wait timer should be 30 minutes"
  }
}

# Test 4: Environment with deployment policies
run "environment_with_deployment_policies" {
  command = plan

  variables {
    repositories = {
      "policy-repo" = {
        description = "Repository with deployment policies"
        environments = {
          "production" = {
            deployment_branch_policy = {
              protected_branches     = true
              custom_branch_policies = false
            }
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_environment.repo["policy-repo/production"].deployment_branch_policy[0].protected_branches == true
    error_message = "Protected branches should be enabled"
  }
}

# Test 5: Environment with secrets and variables
run "environment_with_secrets_and_variables" {
  command = plan

  variables {
    repositories = {
      "secrets-env-repo" = {
        description = "Repository with environment secrets and variables"
        environments = {
          "production" = {
            secrets = {
              "API_KEY"      = "prod-secret"
              "DATABASE_URL" = "prod-db-url"
            }
            secrets_encrypted = {
              "ENCRYPTED_KEY" = "ZW5jcnlwdGVkLXZhbHVl"
            }
            variables = {
              "ENVIRONMENT" = "production"
              "LOG_LEVEL"   = "info"
            }
          }
        }
      }
    }
  }

  # Note: secrets and variables may be empty in plan mode with mock providers
  assert {
    condition     = github_repository_environment.repo["secrets-env-repo/production"].environment == "production"
    error_message = "Should create production environment"
  }

  assert {
    condition     = github_repository_environment.repo["secrets-env-repo/production"].repository == "secrets-env-repo"
    error_message = "Environment should be linked to correct repository"
  }
}

# Test 6: Multiple environments
run "multiple_environments" {
  command = plan

  variables {
    repositories = {
      "multi-env-repo" = {
        description = "Repository with multiple environments"
        environments = {
          "development" = {
            can_admins_bypass = true
            variables = {
              "ENVIRONMENT" = "dev"
            }
          }
          "staging" = {
            wait_timer        = 15
            can_admins_bypass = false
            variables = {
              "ENVIRONMENT" = "staging"
            }
          }
          "production" = {
            wait_timer          = 30
            can_admins_bypass   = false
            prevent_self_review = true
            reviewers_teams     = [123456]
            variables = {
              "ENVIRONMENT" = "production"
            }
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_environment.repo : k => v if startswith(k, "multi-env-repo/") })) == 3
    error_message = "Should create 3 environments"
  }

  assert {
    condition     = github_repository_environment.repo["multi-env-repo/development"].can_admins_bypass == true
    error_message = "Development should allow admin bypass"
  }

  assert {
    condition     = github_repository_environment.repo["multi-env-repo/production"].prevent_self_review == true
    error_message = "Production should prevent self review"
  }
}

# Test 7: Environment with prevent_self_review
run "environment_prevent_self_review" {
  command = plan

  variables {
    repositories = {
      "self-review-repo" = {
        description = "Repository with prevent_self_review"
        environments = {
          "production" = {
            prevent_self_review = true
            reviewers_users     = [123456]
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_environment.repo["self-review-repo/production"].prevent_self_review == true
    error_message = "Should prevent self review"
  }
}

# Test 8: Environment with can_admins_bypass
run "environment_can_admins_bypass" {
  command = plan

  variables {
    repositories = {
      "bypass-repo" = {
        description = "Repository with can_admins_bypass variations"
        environments = {
          "development" = {
            can_admins_bypass = true
          }
          "production" = {
            can_admins_bypass = false
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_environment.repo["bypass-repo/development"].can_admins_bypass == true
    error_message = "Development should allow admin bypass"
  }

  assert {
    condition     = github_repository_environment.repo["bypass-repo/production"].can_admins_bypass == false
    error_message = "Production should not allow admin bypass"
  }
}

# Test 9: Environment with protected branches only
run "environment_protected_branches_only" {
  command = plan

  variables {
    repositories = {
      "protected-repo" = {
        description = "Repository with protected branches policy"
        environments = {
          "staging" = {
            deployment_branch_policy = {
              protected_branches     = true
              custom_branch_policies = false
            }
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_environment.repo["protected-repo/staging"].deployment_branch_policy[0].protected_branches == true
    error_message = "Protected branches should be enabled"
  }

  assert {
    condition     = github_repository_environment.repo["protected-repo/staging"].deployment_branch_policy[0].custom_branch_policies == false
    error_message = "Custom branch policies should be disabled"
  }
}

# Test 10: Environment variables with different value types
run "environment_variables_complex" {
  command = plan

  variables {
    repositories = {
      "complex-vars-repo" = {
        description = "Repository with complex environment variables"
        environments = {
          "production" = {
            variables = {
              "STRING_VAR"  = "simple-string"
              "NUMBER_VAR"  = "12345"
              "URL_VAR"     = "https://example.com"
              "JSON_VAR"    = "{\"key\":\"value\"}"
              "BOOLEAN_VAR" = "true"
            }
          }
        }
      }
    }
  }

  # Note: variables may be empty in plan mode with mock providers
  assert {
    condition     = github_repository_environment.repo["complex-vars-repo/production"].environment == "production"
    error_message = "Should create production environment with complex variables"
  }

  assert {
    condition     = github_repository_environment.repo["complex-vars-repo/production"].repository == "complex-vars-repo"
    error_message = "Environment should be linked to correct repository"
  }
}
