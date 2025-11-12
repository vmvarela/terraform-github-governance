# ========================================================================
# PRESET TESTS
# Tests for repository preset functionality
# ========================================================================

# Mock providers (no real API calls)
mock_provider "github" {}
mock_provider "tls" {}
mock_provider "null" {}
mock_provider "local" {}

# Override data sources to provide mock data
override_data {
  target = data.github_organization.this[0]
  values = {
    id   = "123456"
    plan = "team"
    name = "test-org"
  }
}

override_data {
  target = data.github_repositories.all[0]
  values = {
    names    = []
    repo_ids = []
  }
}

# ========================================================================
# TEST 1: Preset secure-service
# ========================================================================

run "preset_secure_service" {
  command = plan

  variables {
    mode = "organization"
    name = "test-org"
    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "test-api" = {
        description = "Test API"
        preset      = "secure-service"
      }
    }
  }

  # Verify preset applied correctly
  assert {
    condition     = github_repository.repo["test-api"].visibility == "private"
    error_message = "secure-service preset should set visibility to private"
  }

  assert {
    condition     = github_repository.repo["test-api"].has_issues == true
    error_message = "secure-service preset should enable issues"
  }

  assert {
    condition     = github_repository.repo["test-api"].allow_squash_merge == true
    error_message = "secure-service preset should allow squash merge"
  }

  assert {
    condition     = github_repository.repo["test-api"].allow_merge_commit == false
    error_message = "secure-service preset should disable merge commit"
  }

  assert {
    condition     = github_repository.repo["test-api"].allow_rebase_merge == false
    error_message = "secure-service preset should disable rebase merge"
  }

  assert {
    condition     = github_repository.repo["test-api"].delete_branch_on_merge == true
    error_message = "secure-service preset should delete branch on merge"
  }

  assert {
    condition     = github_repository.repo["test-api"].vulnerability_alerts == true
    error_message = "secure-service preset should enable vulnerability alerts"
  }
}

# ========================================================================
# TEST 2: Preset public-library
# ========================================================================

run "preset_public_library" {
  command = plan

  variables {
    mode = "organization"
    name = "test-org"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "test-library" = {
        description = "Test Library"
        preset      = "public-library"
      }
    }
  }

  # Verify preset applied correctly
  assert {
    condition     = github_repository.repo["test-library"].visibility == "public"
    error_message = "public-library preset should set visibility to public"
  }

  assert {
    condition     = github_repository.repo["test-library"].has_discussions == true
    error_message = "public-library preset should enable discussions"
  }

  assert {
    condition     = github_repository.repo["test-library"].allow_squash_merge == true
    error_message = "public-library preset should allow squash merge"
  }

  assert {
    condition     = github_repository.repo["test-library"].allow_merge_commit == true
    error_message = "public-library preset should allow merge commit"
  }

  assert {
    condition     = github_repository.repo["test-library"].allow_rebase_merge == true
    error_message = "public-library preset should allow rebase merge"
  }
}

# ========================================================================
# TEST 3: Preset documentation
# ========================================================================

run "preset_documentation" {
  command = plan

  variables {
    mode = "organization"
    name = "test-org"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "test-docs" = {
        description = "Test Documentation"
        preset      = "documentation"
      }
    }
  }

  # Verify preset applied correctly
  assert {
    condition     = github_repository.repo["test-docs"].visibility == "public"
    error_message = "documentation preset should set visibility to public"
  }

  assert {
    condition     = github_repository.repo["test-docs"].has_wiki == false
    error_message = "documentation preset should disable wiki (uses GitHub Pages instead)"
  }

  assert {
    condition     = github_repository.repo["test-docs"].has_discussions == true
    error_message = "documentation preset should enable discussions"
  }
}

# ========================================================================
# TEST 4: Preset infrastructure
# ========================================================================

run "preset_infrastructure" {
  command = plan

  variables {
    mode = "organization"
    name = "test-org"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "test-infra" = {
        description = "Test Infrastructure"
        preset      = "infrastructure"
      }
    }
  }

  # Verify preset applied correctly
  assert {
    condition     = github_repository.repo["test-infra"].visibility == "private"
    error_message = "infrastructure preset should set visibility to private"
  }

  assert {
    condition     = github_repository.repo["test-infra"].vulnerability_alerts == true
    error_message = "infrastructure preset should enable vulnerability alerts"
  }
}

# ========================================================================
# TEST 5: Override preset values
# ========================================================================

run "preset_override" {
  command = plan

  variables {
    mode = "organization"
    name = "test-org"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "test-override" = {
        description = "Test Override"
        preset      = "secure-service" # preset says private
        visibility  = "public"         # but we override to public
      }
    }
  }

  # Verify repository config overrides preset
  assert {
    condition     = github_repository.repo["test-override"].visibility == "public"
    error_message = "Repository config should override preset visibility"
  }

  assert {
    condition     = github_repository.repo["test-override"].has_issues == true
    error_message = "Non-overridden preset values should still apply"
  }
}

# ========================================================================
# TEST 6: No preset (manual configuration)
# ========================================================================

run "no_preset_manual" {
  command = plan

  variables {
    mode = "organization"
    name = "test-org"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "test-manual" = {
        description        = "Manual Configuration"
        visibility         = "private"
        has_issues         = true
        allow_squash_merge = true
      }
    }
  }

  # Verify manual config works without preset
  assert {
    condition     = github_repository.repo["test-manual"].visibility == "private"
    error_message = "Manual config should work without preset"
  }

  assert {
    condition     = github_repository.repo["test-manual"].has_issues == true
    error_message = "Manual config attributes should be applied"
  }
}

# ========================================================================
# TEST 7: Multiple repositories with different presets
# ========================================================================

run "multiple_presets" {
  command = plan

  variables {
    mode = "organization"
    name = "test-org"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "api-service" = {
        description = "API Service"
        preset      = "secure-service"
      }
      "js-library" = {
        description = "JS Library"
        preset      = "public-library"
      }
      "docs-site" = {
        description = "Documentation Site"
        preset      = "documentation"
      }
      "terraform-infra" = {
        description = "Terraform Infrastructure"
        preset      = "infrastructure"
      }
    }
  }

  # Verify each preset applied correctly
  assert {
    condition     = github_repository.repo["api-service"].visibility == "private"
    error_message = "secure-service preset should be private"
  }

  assert {
    condition     = github_repository.repo["js-library"].visibility == "public"
    error_message = "public-library preset should be public"
  }

  assert {
    condition     = github_repository.repo["docs-site"].visibility == "public"
    error_message = "documentation preset should be public"
  }

  assert {
    condition     = github_repository.repo["terraform-infra"].visibility == "private"
    error_message = "infrastructure preset should be private"
  }
}
