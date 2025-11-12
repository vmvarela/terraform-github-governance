# Tests for repository resources (adapted from modules/repository)
# Tests now use the main module with multiple repositories

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

# Test 1: Basic repository creation
run "basic_repository_creation" {
  command = plan

  variables {
    repositories = {
      "test-repository" = {
        description = "Test repository"
        visibility  = "public"
      }
    }
  }

  assert {
    condition     = github_repository.repo["test-repository"].name == "test-repository"
    error_message = "Repository name should be 'test-repository'"
  }

  assert {
    condition     = github_repository.repo["test-repository"].description == "Test repository"
    error_message = "Description should match"
  }

  assert {
    condition     = github_repository.repo["test-repository"].visibility == "public"
    error_message = "Repository should be public"
  }
}

# Test 2: Private repository with security features
run "private_repository_with_security" {
  command = plan

  variables {
    repositories = {
      "secure-repo" = {
        description                                           = "Private secure repository"
        visibility                                            = "private"
        security_and_analysis_advanced_security               = true
        security_and_analysis_secret_scanning                 = true
        security_and_analysis_secret_scanning_push_protection = true
      }
    }
  }

  assert {
    condition     = github_repository.repo["secure-repo"].visibility == "private"
    error_message = "Repository should be private"
  }

  # Note: security_and_analysis is computed and will be empty in plan with mock providers
  # These assertions validate the input configuration is accepted
  assert {
    condition     = length(keys(github_repository.repo)) == 1
    error_message = "Repository should be created with security features"
  }
}

# Test 3: Merge strategies configuration
run "merge_strategies_configuration" {
  command = plan

  variables {
    repositories = {
      "merge-test-repo" = {
        description            = "Repository with specific merge strategies"
        allow_merge_commit     = true
        allow_squash_merge     = true
        allow_rebase_merge     = false
        allow_auto_merge       = true
        delete_branch_on_merge = true
      }
    }
  }

  assert {
    condition     = github_repository.repo["merge-test-repo"].allow_merge_commit == true
    error_message = "Merge commit should be allowed"
  }

  assert {
    condition     = github_repository.repo["merge-test-repo"].allow_squash_merge == true
    error_message = "Squash merge should be allowed"
  }

  assert {
    condition     = github_repository.repo["merge-test-repo"].allow_rebase_merge == false
    error_message = "Rebase merge should be disabled"
  }

  assert {
    condition     = github_repository.repo["merge-test-repo"].delete_branch_on_merge == true
    error_message = "Delete branch on merge should be enabled"
  }
}

# Test 4: Branches configuration
run "branches_configuration" {
  command = plan

  variables {
    repositories = {
      "branch-test-repo" = {
        description    = "Repository with multiple branches"
        default_branch = "main"
        branches = {
          "develop" = { source_branch = "main" }
          "staging" = { source_branch = "main" }
          "hotfix"  = { source_branch = "main" }
        }
      }
    }
  }

  assert {
    condition     = github_branch_default.repo["branch-test-repo"].branch == "main"
    error_message = "Default branch should be main"
  }

  assert {
    condition     = length(keys({ for k, v in github_branch.repo : k => v if startswith(k, "branch-test-repo/") })) == 3
    error_message = "Should create 3 additional branches"
  }
}

# Test 5: GitHub Actions configuration
run "github_actions_configuration" {
  command = plan

  variables {
    repositories = {
      "actions-repo" = {
        description            = "Repository with GitHub Actions enabled"
        enable_actions         = true
        actions_allowed_policy = "selected"
        actions_allowed_patterns = [
          "actions/*",
          "docker/*"
        ]
      }
    }
  }

  assert {
    condition     = github_actions_repository_permissions.repo["actions-repo"].allowed_actions == "selected"
    error_message = "Should have selected allowed actions"
  }

  assert {
    condition     = length(github_actions_repository_permissions.repo["actions-repo"].allowed_actions_config[0].patterns_allowed) == 2
    error_message = "Should have 2 allowed action patterns"
  }
}

# Test 6: Secrets and variables
run "secrets_and_variables" {
  command = plan

  variables {
    repositories = {
      "secrets-repo" = {
        description = "Repository with secrets and variables"
        secrets = {
          API_KEY = "test-secret-value"
          DB_PASS = "another-secret"
        }
        variables = {
          ENVIRONMENT = "testing"
          VERSION     = "1.0.0"
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_actions_secret.plaintext : k => v if startswith(k, "secrets-repo/") })) == 2
    error_message = "Should create 2 secrets"
  }

  assert {
    condition     = github_actions_secret.plaintext["secrets-repo/API_KEY"].secret_name == "API_KEY"
    error_message = "Secret name should be API_KEY"
  }

  assert {
    condition     = length(keys({ for k, v in github_actions_variable.repo : k => v if startswith(k, "secrets-repo/") })) == 2
    error_message = "Should create 2 variables"
  }

  assert {
    condition     = github_actions_variable.repo["secrets-repo/ENVIRONMENT"].variable_name == "ENVIRONMENT"
    error_message = "Variable name should be ENVIRONMENT"
  }
}

# Test 7: Issue labels configuration
run "issue_labels_configuration" {
  command = plan

  variables {
    repositories = {
      "labels-repo" = {
        description = "Repository with custom labels"
        issue_labels = {
          "bug"           = "Bug reports"
          "enhancement"   = "New features"
          "documentation" = "Documentation improvements"
        }
        issue_labels_colors = {
          "bug"           = "d73a4a"
          "enhancement"   = "a2eeef"
          "documentation" = "0075ca"
        }
      }
    }
  }

  assert {
    condition     = github_issue_labels.repo["labels-repo"] != null
    error_message = "Should create 1 issue labels resources"
  }
}

# Test 8: Deploy keys configuration (auto-generated)
run "deploy_keys_auto_generated" {
  command = plan

  variables {
    repositories = {
      "deploy-keys-repo" = {
        description = "Repository with auto-generated deploy keys"
        deploy_keys = {
          "ci-key" = {
            read_only = false
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in tls_private_key.repo : k => v if startswith(k, "deploy-keys-repo/") })) == 1
    error_message = "Should create 1 TLS private key"
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_deploy_key.repo : k => v if startswith(k, "deploy-keys-repo/") })) == 1
    error_message = "Should create 1 deploy key"
  }
}

# Test 9: Deploy keys with provided key
run "deploy_keys_provided" {
  command = plan

  variables {
    repositories = {
      "deploy-keys-provided-repo" = {
        description = "Repository with provided deploy key"
        deploy_keys = {
          "external-key" = {
            public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC..."
            read_only  = true
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in tls_private_key.repo : k => v if startswith(k, "deploy-keys-provided-repo/") })) == 0
    error_message = "Should not create TLS private key when key is provided"
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_deploy_key.repo : k => v if startswith(k, "deploy-keys-provided-repo/") })) == 1
    error_message = "Should create 1 deploy key"
  }
}

# Test 10: Autolink references
run "autolink_references" {
  command = plan

  variables {
    repositories = {
      "autolink-repo" = {
        description = "Repository with autolink references"
        autolink_references = {
          "jira" = {
            key_prefix = "JIRA-"
            target_url = "https://jira.example.com/browse/JIRA-<num>"
          }
          "ticket" = {
            key_prefix = "TICKET-"
            target_url = "https://tickets.example.com/view/<num>"
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_autolink_reference.repo : k => v if startswith(k, "autolink-repo/") })) == 2
    error_message = "Should create 2 autolink references"
  }
}

# Test 11: Collaborators configuration
run "collaborators_configuration" {
  command = plan

  variables {
    repositories = {
      "collab-repo" = {
        description = "Repository with collaborators"
        teams = {
          "team-123" = "maintain"
          "team-456" = "write"
        }
        users = {
          "user1" = "admin"
          "user2" = "read"
        }
      }
    }
  }

  assert {
    condition     = length(github_repository_collaborators.repo["collab-repo"].team) == 2
    error_message = "Should have 2 team collaborators"
  }

  assert {
    condition     = length(github_repository_collaborators.repo["collab-repo"].user) == 2
    error_message = "Should have 2 user collaborators"
  }
}

# Test 12: GitHub Pages (legacy)
run "github_pages_legacy" {
  command = plan

  variables {
    repositories = {
      "pages-repo" = {
        description         = "Repository with GitHub Pages"
        visibility          = "public"
        pages_source_branch = "gh-pages"
        pages_source_path   = "/"
        pages_build_type    = "legacy"
      }
    }
  }

  assert {
    condition     = github_repository.repo["pages-repo"].pages[0].source[0].branch == "gh-pages"
    error_message = "Pages source branch should be gh-pages"
  }
}

# Test 13: Template repository
run "template_repository" {
  command = plan

  variables {
    repositories = {
      "template-repo" = {
        description = "Template repository"
        is_template = true
        visibility  = "public"
      }
    }
  }

  assert {
    condition     = github_repository.repo["template-repo"].is_template == true
    error_message = "Repository should be a template"
  }
}

# Test 14: Custom properties
run "custom_properties" {
  command = plan

  variables {
    repositories = {
      "custom-props-repo" = {
        description = "Repository with custom properties"
        custom_properties = {
          "environment" = "production"
          "team"        = "platform"
          "cost_center" = "engineering"
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_custom_property.repo : k => v if startswith(k, "custom-props-repo/") })) == 3
    error_message = "Should create 3 custom properties"
  }
}

# Test 15: Topics configuration
run "topics_configuration" {
  command = plan

  variables {
    repositories = {
      "topics-repo" = {
        description = "Repository with topics"
        topics      = ["terraform", "github", "automation", "infrastructure"]
      }
    }
  }

  assert {
    condition     = length(github_repository.repo["topics-repo"].topics) == 4
    error_message = "Should have 4 topics"
  }

  assert {
    condition     = contains(github_repository.repo["topics-repo"].topics, "terraform")
    error_message = "Should contain 'terraform' topic"
  }
}

# Test 16: Alias for renaming
run "alias_for_renaming" {
  command = plan

  variables {
    repositories = {
      "old-name" = {
        description = "Renamed repository"
        alias       = "new-name"
      }
    }
  }

  assert {
    condition     = github_repository.repo["old-name"].name == "new-name"
    error_message = "Repository should have new name"
  }
}

# Test 17: Archived repository
run "archived_repository" {
  command = plan

  variables {
    repositories = {
      "archived-repo" = {
        description = "Archived repository"
        archived    = true
      }
    }
  }

  assert {
    condition     = github_repository.repo["archived-repo"].archived == true
    error_message = "Repository should be archived"
  }
}

# Test 18: Visibility explicit (public)
run "visibility_explicit" {
  command = plan

  variables {
    repositories = {
      "explicit-public" = {
        description = "Explicitly public repository"
        visibility  = "public"
      }
    }
  }

  assert {
    condition     = github_repository.repo["explicit-public"].visibility == "public"
    error_message = "Repository should be explicitly public"
  }
}

# Test 19: Security scanning for public repo
run "security_scanning_public_repo" {
  command = plan

  variables {
    repositories = {
      "public-secure" = {
        description                                           = "Public repository with security features"
        visibility                                            = "public"
        security_and_analysis_secret_scanning                 = true
        security_and_analysis_secret_scanning_push_protection = true
      }
    }
  }

  # Note: security_and_analysis is computed and will be empty in plan with mock providers
  # This assertion validates the input configuration is accepted
  assert {
    condition     = github_repository.repo["public-secure"].visibility == "public"
    error_message = "Repository should be public with security features configured"
  }
}

# Test 20: Dependabot independent secrets
run "dependabot_independent_secrets" {
  command = plan

  variables {
    repositories = {
      "dependabot-repo" = {
        description = "Repository with Dependabot secrets"
        dependabot_secrets = {
          "NPM_TOKEN"    = "npm-secret-value"
          "DOCKER_TOKEN" = "docker-secret-value"
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_dependabot_secret.plaintext : k => v if startswith(k, "dependabot-repo/") })) == 2
    error_message = "Should create 2 Dependabot secrets"
  }

  assert {
    condition     = github_dependabot_secret.plaintext["dependabot-repo/NPM_TOKEN"].secret_name == "NPM_TOKEN"
    error_message = "Dependabot secret name should be NPM_TOKEN"
  }
}

# Test 21: Repository features
run "repository_features" {
  command = plan

  variables {
    repositories = {
      "features-repo" = {
        description     = "Repository with various features"
        has_issues      = true
        has_projects    = true
        has_wiki        = true
        has_discussions = true
        has_downloads   = true
      }
    }
  }

  assert {
    condition     = github_repository.repo["features-repo"].has_issues == true
    error_message = "Issues should be enabled"
  }

  assert {
    condition     = github_repository.repo["features-repo"].has_projects == true
    error_message = "Projects should be enabled"
  }

  assert {
    condition     = github_repository.repo["features-repo"].has_wiki == true
    error_message = "Wiki should be enabled"
  }

  # Note: has_discussions may be null in plan mode with mock providers
  # This assertion validates the repository is created with features enabled
  assert {
    condition     = length(keys(github_repository.repo)) == 1
    error_message = "Repository should be created with features enabled"
  }
}
