# Tests for Dependabot Security Updates
# Covers: github_repository_dependabot_security_updates resource

mock_provider "github" {}
mock_provider "tls" {}
mock_provider "null" {}
mock_provider "local" {}

variables {
  name       = "test-org"
  github_org = "test-org"
}

override_data {
  target = data.github_organization.this[0]
  values = {
    plan = "enterprise"
  }
}

override_data {
  target = data.github_repositories.all[0]
  values = {
    names = []
  }
}

# Test 1: Basic Dependabot security updates enabled
run "basic_dependabot_security_updates_enabled" {
  command = plan

  variables {
    repositories = {
      "secure-repo" = {
        description                        = "Repository with Dependabot security updates"
        visibility                         = "private"
        enable_dependabot_security_updates = true
      }
    }
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["secure-repo"].enabled == true
    error_message = "Dependabot security updates should be enabled"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["secure-repo"].repository == "secure-repo"
    error_message = "Should be associated with secure-repo"
  }
}

# Test 2: Dependabot security updates disabled explicitly
run "dependabot_security_updates_disabled" {
  command = plan

  variables {
    repositories = {
      "no-dependabot-repo" = {
        description                        = "Repository without Dependabot security updates"
        visibility                         = "private"
        enable_dependabot_security_updates = false
      }
    }
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["no-dependabot-repo"].enabled == false
    error_message = "Dependabot security updates should be disabled (enabled = false)"
  }
}

# Test 3: Dependabot enabled from settings
run "dependabot_inherited_from_settings" {
  command = plan

  variables {
    settings = {
      enable_dependabot_security_updates = true
    }
    repositories = {
      "inherited-repo" = {
        description = "Repository inheriting Dependabot from settings"
        visibility  = "private"
      }
    }
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["inherited-repo"].enabled == true
    error_message = "Should inherit Dependabot security updates from settings"
  }
}

# Test 4: Settings enforces policy (overrides repository)
# Settings has highest priority to enforce organization-wide policies
run "settings_enforces_policy" {
  command = plan

  variables {
    settings = {
      enable_dependabot_security_updates = true # Enforce at org level
    }
    repositories = {
      "enforced-repo" = {
        description                        = "Repository with enforced Dependabot"
        visibility                         = "private"
        enable_dependabot_security_updates = false # Overridden by settings
      }
    }
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["enforced-repo"].enabled == true
    error_message = "Settings should enforce Dependabot (settings > repository > defaults)"
  }
}

# Test 5: Repository value used when settings is not defined
run "repository_value_when_no_settings" {
  command = plan

  variables {
    # settings.enable_dependabot_security_updates not defined
    repositories = {
      "repo-controlled" = {
        description                        = "Repository controls its own Dependabot"
        visibility                         = "private"
        enable_dependabot_security_updates = true
      }
    }
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["repo-controlled"].enabled == true
    error_message = "Repository value should be used when settings is not defined"
  }
}

# Test 6: Dependabot with vulnerability alerts
run "dependabot_with_vulnerability_alerts" {
  command = plan

  variables {
    repositories = {
      "secure-combo-repo" = {
        description                        = "Repository with Dependabot and vulnerability alerts"
        visibility                         = "private"
        enable_vulnerability_alerts        = true
        enable_dependabot_security_updates = true
      }
    }
  }

  assert {
    condition     = github_repository.repo["secure-combo-repo"].vulnerability_alerts == true
    error_message = "Should have vulnerability alerts enabled"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["secure-combo-repo"].enabled == true
    error_message = "Should have Dependabot security updates enabled"
  }
}

# Test 7: Multiple repositories with different Dependabot configurations
run "multiple_repos_different_dependabot_config" {
  command = plan

  variables {
    repositories = {
      "secure-api" = {
        description                        = "Secure API"
        visibility                         = "private"
        enable_dependabot_security_updates = true
      }
      "legacy-app" = {
        description                        = "Legacy app without Dependabot"
        visibility                         = "private"
        enable_dependabot_security_updates = false
      }
      "new-service" = {
        description                        = "New service with Dependabot"
        visibility                         = "private"
        enable_dependabot_security_updates = true
      }
    }
  }

  assert {
    condition     = length(keys(github_repository_dependabot_security_updates.repo)) == 3
    error_message = "Should create Dependabot resource for all 3 repositories"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["secure-api"].enabled == true
    error_message = "secure-api should have Dependabot enabled (true)"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["new-service"].enabled == true
    error_message = "new-service should have Dependabot enabled (true)"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["legacy-app"].enabled == false
    error_message = "legacy-app should have Dependabot disabled (false)"
  }
}

# Test 8: Dependabot with defaults
run "dependabot_with_defaults" {
  command = plan

  variables {
    defaults = {
      enable_dependabot_security_updates = true
    }
    repositories = {
      "default-repo" = {
        description = "Repository using defaults"
        visibility  = "private"
      }
    }
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["default-repo"].enabled == true
    error_message = "Should inherit Dependabot from defaults"
  }
}

# Test 9: Priority order (settings > repository > defaults)
run "dependabot_priority_order" {
  command = plan

  variables {
    defaults = {
      enable_dependabot_security_updates = false
    }
    settings = {
      enable_dependabot_security_updates = true # Highest priority (policy enforcement)
    }
    repositories = {
      "priority-repo-1" = {
        description = "Uses settings (overrides defaults)"
        visibility  = "private"
        # No value set, inherits from settings
      }
      "priority-repo-2" = {
        description                        = "Settings overrides repository"
        visibility                         = "private"
        enable_dependabot_security_updates = false # Overridden by settings
      }
    }
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["priority-repo-1"].enabled == true
    error_message = "priority-repo-1 should use settings value (enabled = true)"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["priority-repo-2"].enabled == true
    error_message = "priority-repo-2 settings should override repository (enabled = true from settings)"
  }
}

# Test 10: Dependabot with public repository
run "dependabot_with_public_repo" {
  command = plan

  variables {
    repositories = {
      "public-secure-repo" = {
        description                        = "Public repository with Dependabot"
        visibility                         = "public"
        enable_dependabot_security_updates = true
      }
    }
  }

  assert {
    condition     = github_repository.repo["public-secure-repo"].visibility == "public"
    error_message = "Repository should be public"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["public-secure-repo"].enabled == true
    error_message = "Public repository should have Dependabot enabled"
  }
}

# Test 11: Dependabot with advanced security features
run "dependabot_with_advanced_security" {
  command = plan

  variables {
    repositories = {
      "enterprise-repo" = {
        description                            = "Enterprise repo with full security"
        visibility                             = "private"
        enable_vulnerability_alerts            = true
        enable_dependabot_security_updates     = true
        enable_advanced_security               = true
        enable_secret_scanning                 = true
        enable_secret_scanning_push_protection = true
      }
    }
  }

  assert {
    condition     = github_repository.repo["enterprise-repo"].vulnerability_alerts == true
    error_message = "Should have vulnerability alerts"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["enterprise-repo"].enabled == true
    error_message = "Should have Dependabot security updates"
  }

  assert {
    condition     = github_repository.repo["enterprise-repo"].security_and_analysis[0].advanced_security[0].status == "enabled"
    error_message = "Should have advanced security enabled"
  }

  assert {
    condition     = github_repository.repo["enterprise-repo"].security_and_analysis[0].secret_scanning[0].status == "enabled"
    error_message = "Should have secret scanning enabled"
  }

  assert {
    condition     = github_repository.repo["enterprise-repo"].security_and_analysis[0].secret_scanning_push_protection[0].status == "enabled"
    error_message = "Should have secret scanning push protection enabled"
  }
}

# Test 12: Dependabot disabled by default when not specified
run "dependabot_default_behavior" {
  command = plan

  variables {
    repositories = {
      "default-behavior-repo" = {
        description = "Repository with default Dependabot behavior"
        visibility  = "private"
        # enable_dependabot_security_updates not specified
      }
    }
  }

  # When not specified and no settings/defaults, should not be created
  assert {
    condition     = length(keys({ for k, v in github_repository_dependabot_security_updates.repo : k => v if k == "default-behavior-repo" })) == 0
    error_message = "Should not create Dependabot when not explicitly enabled"
  }
}

# Test 13: Dependabot with template repository
run "dependabot_with_template" {
  command = plan

  variables {
    repositories = {
      "template-repo" = {
        description                        = "Template repository with Dependabot"
        visibility                         = "public"
        is_template                        = true
        enable_dependabot_security_updates = true
      }
    }
  }

  assert {
    condition     = github_repository.repo["template-repo"].is_template == true
    error_message = "Should be a template repository"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["template-repo"].enabled == true
    error_message = "Template repository should have Dependabot enabled"
  }
}

# Test 14: Dependabot with archived repository
run "dependabot_with_archived_repo" {
  command = plan

  variables {
    repositories = {
      "archived-repo" = {
        description                        = "Archived repository"
        visibility                         = "private"
        archived                           = true
        enable_dependabot_security_updates = true
      }
    }
  }

  assert {
    condition     = github_repository.repo["archived-repo"].archived == true
    error_message = "Should be archived"
  }

  # Dependabot can still be configured for archived repos
  assert {
    condition     = github_repository_dependabot_security_updates.repo["archived-repo"].enabled == true
    error_message = "Archived repository can have Dependabot configured"
  }
}

# Test 15: Dependabot in project mode
run "dependabot_in_project_mode" {
  command = plan

  variables {
    mode = "project"
    project = {
      name         = "test-project"
      repositories = ["dependabot-project-repo"]
    }
    settings = {
      enable_dependabot_security_updates = true # Enforce at project level
    }
    repositories = {
      "dependabot-project-repo" = {
        description = "Project mode repository with Dependabot"
        visibility  = "private"
        # Value inherited from settings
      }
    }
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["dependabot-project-repo"].enabled == true
    error_message = "dependabot-project-repo should inherit from settings (enabled = true)"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.repo["dependabot-project-repo"].repository == "dependabot-project-repo"
    error_message = "dependabot-project-repo should have correct repository name"
  }
}
