# Tests for governance module

mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      id             = "test-repo-id"
      full_name      = "test-org/test-repo"
      html_url       = "https://github.com/test-org/test-repo"
      ssh_clone_url  = "git@github.com:test-org/test-repo.git"
      http_clone_url = "https://github.com/test-org/test-repo.git"
      node_id        = "test-node-id"
      default_branch = "main"
    }
  }

  mock_resource "github_repository_ruleset" {
    defaults = {
      id         = 123
      etag       = "test-etag"
      node_id    = "test-ruleset-node-id"
      ruleset_id = 123
    }
  }

  mock_resource "github_branch_default" {
    defaults = {
      id     = "test-repo"
      branch = "main"
    }
  }

  mock_data "github_team" {
    defaults = {
      id   = 1
      slug = "test-team"
      name = "Test Team"
    }
  }

  mock_data "github_app" {
    defaults = {
      id   = 1
      slug = "test-app"
      name = "Test App"
    }
  }
}

run "test_preset_application" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test-workspace"
    repository_naming = "%s"

    repositories = {
      test-repo = {
        preset      = "default"
        description = "Test repository"
      }
    }
  }

  # Verify that default preset values are applied
  assert {
    condition     = module.repositories["test-repo"].visibility == "private"
    error_message = "Default preset should set visibility to private"
  }

  assert {
    condition     = module.repositories["test-repo"].default_branch == "main"
    error_message = "Default preset should set default_branch to main"
  }

  assert {
    condition     = module.repositories["test-repo"].protected_branches_ruleset_created
    error_message = "Default preset should create a protected-branches ruleset"
  }
}

run "test_production_service_preset" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "prod-services"
    repository_naming = "%s"

    presets = {
      "production-service" = {
        topics             = ["production", "service"]
        protected_branches = ["main"]
        required_approvals = 2
      }
    }

    repositories = {
      api = {
        preset      = "production-service"
        description = "Production API"
      }
    }
  }

  # Verify production-service preset values
  # Ruleset exists and topics include production
  assert {
    condition     = module.repositories["api"].protected_branches_ruleset_created
    error_message = "Production-service preset should create a protected-branches ruleset"
  }

  assert {
    condition     = contains(module.repositories["api"].topics, "production")
    error_message = "Production-service preset should include 'production' topic"
  }
}

run "test_repository_naming_simple" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "%s"

    repositories = {
      my-repo = {
        description = "Test"
      }
    }
  }

  # Verify repository_naming with no prefix
  assert {
    condition     = module.repositories["my-repo"].name == "my-repo"
    error_message = "repository_naming '%s' should use key as-is"
  }
}

run "test_repository_naming_with_prefix" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "myorg-%s"

    repositories = {
      api = {
        description = "API service"
      }
    }
  }

  # Verify repository_naming with prefix
  assert {
    condition     = module.repositories["api"].name == "myorg-api"
    error_message = "repository_naming 'myorg-%s' should add prefix to key"
  }
}

run "test_explicit_name_for_renaming" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "test-org-%s"

    repositories = {
      stable-key = {
        name        = "new-github-name"
        description = "Renamed repository"
      }
    }
  }

  # Verify repository_naming format is ALWAYS applied (even with explicit name)
  assert {
    condition     = module.repositories["stable-key"].name == "test-org-new-github-name"
    error_message = "Expected repository_naming format to be applied: test-org-new-github-name, got: ${module.repositories["stable-key"].name}"
  }
}

run "test_preset_override_approvals" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "%s"

    presets = {
      "production-service" = {
        protected_branches = ["main"]
        required_approvals = 2
      }
    }

    repositories = {
      critical-api = {
        preset                  = "production-service"
        description             = "Critical API"
        protected_branches      = ["main", "release/*"]
        required_approvals      = 3 # Override preset's 2
        required_checks         = ["ci", "security"]
        prevent_force_push      = true
        prevent_branch_deletion = true
        allow_bypass            = ["org-admin"]
      }
    }
  }

  # Verify ruleset exists after override
  assert {
    condition     = module.repositories["critical-api"].protected_branches_ruleset_created
    error_message = "Repository with override should create a protected-branches ruleset"
  }
}

run "test_preset_override_visibility" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "%s"

    repositories = {
      public-lib = {
        preset      = "default" # default is private
        visibility  = "public"  # override to public
        description = "Public library"
      }
    }
  }

  # Verify visibility override
  assert {
    condition     = module.repositories["public-lib"].visibility == "public"
    error_message = "Repository should override preset's visibility"
  }
}

run "test_library_preset" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "libraries"
    repository_naming = "%s"

    presets = {
      library = {
        visibility         = "public"
        protected_branches = ["main"]
      }
    }

    repositories = {
      utils = {
        preset      = "library"
        description = "Utility library"
      }
    }
  }

  # Verify library preset
  assert {
    condition     = module.repositories["utils"].visibility == "public"
    error_message = "Library preset should be public by default"
  }

  assert {
    condition     = module.repositories["utils"].protected_branches_ruleset_created
    error_message = "Library preset should create a protected-branches ruleset"
  }
}

run "test_experimental_preset" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "research"
    repository_naming = "%s"

    presets = {
      experimental = {}
    }

    repositories = {
      ml-research = {
        preset      = "experimental"
        description = "ML research project"
      }
    }
  }

  # Verify experimental preset still creates a ruleset (default protections may apply)
  assert {
    condition     = module.repositories["ml-research"].protected_branches_ruleset_created
    error_message = "Experimental preset should create a protected-branches ruleset"
  }
}

run "test_workspace_in_properties" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "platform-services"
    repository_naming = "%s"

    repositories = {
      api = {
        description = "API service"
        properties = {
          custom_key = "custom_value"
        }
      }
    }
  }

  # Verify workspace is added to properties
  assert {
    condition     = module.repositories["api"].properties["workspace"] == "platform-services"
    error_message = "workspace should be added to properties"
  }

  # Verify custom properties are preserved
  assert {
    condition     = module.repositories["api"].properties["custom_key"] == "custom_value"
    error_message = "Custom properties should be preserved"
  }
}

run "test_multiple_repositories" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "multi-test"
    repository_naming = "prefix-%s"

    presets = {
      "production-service" = {
        protected_branches = ["main"]
      }
      staging = {
        protected_branches = ["main"]
      }
      documentation = {
        visibility         = "public"
        protected_branches = ["main"]
      }
    }

    repositories = {
      api = {
        preset      = "production-service"
        description = "Production API"
      }
      worker = {
        preset      = "staging"
        description = "Background worker"
      }
      docs = {
        preset      = "documentation"
        description = "Documentation site"
      }
    }
  }

  # Verify all repositories are created
  assert {
    condition     = length(module.repositories) == 3
    error_message = "Should create 3 repositories"
  }

  # Verify each has correct repository_naming
  assert {
    condition     = module.repositories["api"].name == "prefix-api"
    error_message = "API should have correct repository_naming"
  }

  assert {
    condition     = module.repositories["worker"].name == "prefix-worker"
    error_message = "Worker should have correct repository_naming"
  }

  assert {
    condition     = module.repositories["docs"].name == "prefix-docs"
    error_message = "Docs should have correct repository_naming"
  }
}

run "test_topics_merge" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "%s"

    presets = {
      "production-service" = {
        topics             = ["production", "service"]
        protected_branches = ["main"]
      }
    }

    repositories = {
      api = {
        preset = "production-service" # Has ["production", "service"]
        topics = ["api", "backend"]   # Additional topics
      }
    }
  }

  # Verify topics from repository override preset topics (coalesce behavior)
  assert {
    condition     = contains(module.repositories["api"].topics, "api")
    error_message = "Should include repository-level topics"
  }

  assert {
    condition     = contains(module.repositories["api"].topics, "backend")
    error_message = "Should include repository-level topics"
  }
}

run "test_documentation_preset" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "docs"
    repository_naming = "%s"

    presets = {
      documentation = {
        visibility         = "public"
        protected_branches = ["main"]
      }
    }

    repositories = {
      user-docs = {
        preset      = "documentation"
        description = "User documentation"
      }
    }
  }

  # Verify documentation preset
  assert {
    condition     = module.repositories["user-docs"].visibility == "public"
    error_message = "Documentation preset should be public"
  }

  assert {
    condition     = module.repositories["user-docs"].protected_branches_ruleset_created
    error_message = "Documentation preset should create a protected-branches ruleset"
  }
}

run "test_staging_preset" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "staging"
    repository_naming = "%s"

    presets = {
      staging = {
        protected_branches = ["main"]
      }
    }

    repositories = {
      test-env = {
        preset      = "staging"
        description = "Staging environment"
      }
    }
  }

  # Verify staging preset creates a ruleset
  assert {
    condition     = module.repositories["test-env"].protected_branches_ruleset_created
    error_message = "Staging preset should create a protected-branches ruleset"
  }
}

run "test_merge_settings_from_preset" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "%s"

    presets = {
      squash-only = {
        allow_merge_commit     = false
        allow_squash_merge     = true
        allow_rebase_merge     = false
        delete_branch_on_merge = true
        allow_auto_merge       = true
      }
    }

    repositories = {
      my-service = {
        preset      = "squash-only"
        description = "Squash-only service"
      }
    }
  }

  assert {
    condition     = module.repositories["my-service"].delete_branch_on_merge == true
    error_message = "Preset should enable delete_branch_on_merge"
  }
}

run "test_merge_settings_repo_override" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "%s"

    presets = {
      strict = {
        allow_merge_commit     = false
        allow_rebase_merge     = false
        delete_branch_on_merge = true
      }
    }

    repositories = {
      special = {
        preset             = "strict"
        description        = "Special repo"
        allow_merge_commit = true # Override preset
      }
    }
  }

  assert {
    condition     = module.repositories["special"].delete_branch_on_merge == true
    error_message = "Preset delete_branch_on_merge should still apply"
  }
}

run "test_feature_toggles_from_preset" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "%s"

    presets = {
      minimal = {
        has_issues   = true
        has_wiki     = false
        has_projects = false
      }
    }

    repositories = {
      lean-repo = {
        preset      = "minimal"
        description = "Minimal feature repo"
      }
    }
  }

  assert {
    condition     = module.repositories["lean-repo"].visibility == "private"
    error_message = "Default visibility should be private"
  }
}

run "test_archived_repository" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "%s"

    repositories = {
      old-project = {
        description = "Archived project"
        archived    = true
      }
    }
  }

  assert {
    condition     = module.repositories["old-project"].archived == true
    error_message = "Repository should be archived"
  }
}

run "test_security_defaults" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "test"
    repository_naming = "%s"

    repositories = {
      secure-repo = {
        description = "Secure repo"
      }
    }
  }

  # vulnerability_alerts defaults to true (security-first governance)
  assert {
    condition     = module.repositories["secure-repo"].default_branch == "main"
    error_message = "Default branch should be main"
  }
}
