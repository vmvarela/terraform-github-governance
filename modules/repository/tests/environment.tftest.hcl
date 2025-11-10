# Tests for environment module with mock providers

mock_provider "github" {}

variables {
  name       = "test-environment-repo"
  visibility = "public"
  auto_init  = true
}

# Test 1: Basic environment without configuration
run "basic_environment" {
  command = plan

  variables {
    environments = {
      "production" = {}
    }
  }

  assert {
    condition     = length(module.environment) == 1
    error_message = "Should create 1 environment"
  }

  assert {
    condition     = module.environment["production"].environment.environment == "production"
    error_message = "Environment name should be 'production'"
  }
}

# Test 2: Ambiente con reviewers
run "environment_with_reviewers" {
  command = plan

  variables {
    environments = {
      "production" = {
        reviewers_teams = [123456, 789012]
        reviewers_users = [111111, 222222]
      }
    }
  }

  assert {
    condition     = length(module.environment["production"].environment.reviewers[0].teams) == 2
    error_message = "Should have 2 team reviewers"
  }

  assert {
    condition     = length(module.environment["production"].environment.reviewers[0].users) == 2
    error_message = "Should have 2 user reviewers"
  }
}

# Test 3: Ambiente con wait timer
run "environment_with_wait_timer" {
  command = plan

  variables {
    environments = {
      "staging" = {
        wait_timer = 30
      }
    }
  }

  assert {
    condition     = module.environment["staging"].environment.wait_timer == 30
    error_message = "Wait timer should be 30 minutes"
  }
}

# Test 4: Ambiente con deployment policies
run "environment_with_deployment_policies" {
  command = plan

  variables {
    environments = {
      "production" = {
        protected_branches     = true
        custom_branch_policies = ["main", "release/*"]
      }
    }
  }

  assert {
    condition     = module.environment["production"].environment.deployment_branch_policy[0].custom_branch_policies == true
    error_message = "Custom branch policies should be enabled"
  }

  assert {
    condition     = length(module.environment["production"].deployment_policies) == 2
    error_message = "Should create 2 deployment policies"
  }
}

# Test 5: Ambiente con secrets y variables
run "environment_with_secrets_and_variables" {
  command = plan

  variables {
    environments = {
      "production" = {
        secrets = {
          "API_KEY"      = "prod-secret"
          "DATABASE_URL" = "prod-db-url"
        }
        secrets_encrypted = {
          "ENCRYPTED_KEY" = "ZW5jcnlwdGVkLXZhbHVl" # base64 encoded "encrypted-value"
        }
        variables = {
          "ENVIRONMENT" = "production"
          "LOG_LEVEL"   = "info"
        }
      }
    }
  }

  assert {
    condition     = length(module.environment["production"].secrets_plaintext) == 2
    error_message = "Should create 2 plaintext secrets"
  }

  assert {
    condition     = length(module.environment["production"].secrets_encrypted) == 1
    error_message = "Should create 1 encrypted secret"
  }

  assert {
    condition     = length(module.environment["production"].variables) == 2
    error_message = "Should create 2 variables"
  }

  assert {
    condition     = module.environment["production"].variables["ENVIRONMENT"].value == "production"
    error_message = "ENVIRONMENT variable should be 'production'"
  }
}

# Test 6: Multiple environments
run "multiple_environments" {
  command = plan

  variables {
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

  assert {
    condition     = length(module.environment) == 3
    error_message = "Should create 3 environments"
  }

  assert {
    condition     = module.environment["development"].environment.can_admins_bypass == true
    error_message = "Development should allow admin bypass"
  }

  assert {
    condition     = module.environment["production"].environment.prevent_self_review == true
    error_message = "Production should prevent self review"
  }
}

# Test 7: Ambiente con prevent_self_review
run "environment_prevent_self_review" {
  command = plan

  variables {
    environments = {
      "production" = {
        prevent_self_review = true
        reviewers_users     = [123456]
      }
    }
  }

  assert {
    condition     = module.environment["production"].environment.prevent_self_review == true
    error_message = "Should prevent self review"
  }
}

# Test 8: Ambiente con can_admins_bypass
run "environment_can_admins_bypass" {
  command = plan

  variables {
    environments = {
      "development" = {
        can_admins_bypass = true
      }
      "production" = {
        can_admins_bypass = false
      }
    }
  }

  assert {
    condition     = module.environment["development"].environment.can_admins_bypass == true
    error_message = "Development should allow admin bypass"
  }

  assert {
    condition     = module.environment["production"].environment.can_admins_bypass == false
    error_message = "Production should not allow admin bypass"
  }
}

# Test 9: Ambiente solo con protected branches (sin custom policies)
run "environment_protected_branches_only" {
  command = plan

  variables {
    environments = {
      "staging" = {
        protected_branches = true
      }
    }
  }

  assert {
    condition     = module.environment["staging"].environment.deployment_branch_policy[0].protected_branches == true
    error_message = "Protected branches should be enabled"
  }

  assert {
    condition     = module.environment["staging"].environment.deployment_branch_policy[0].custom_branch_policies == false
    error_message = "Custom branch policies should be disabled"
  }
}

# Test 10: Variables de ambiente con diferentes tipos de valores
run "environment_variables_complex" {
  command = plan

  variables {
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

  assert {
    condition     = length(module.environment["production"].variables) == 5
    error_message = "Should create 5 variables"
  }

  assert {
    condition     = module.environment["production"].variables["URL_VAR"].value == "https://example.com"
    error_message = "URL_VAR should have correct value"
  }
}
