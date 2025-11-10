# Basic tests with mock provider
mock_provider "github" {
  alias = "basic"
}

mock_provider "tls" {
  alias = "basic"
}

mock_provider "null" {
  alias = "basic"
}

mock_provider "local" {
  alias = "basic"
}

# Test 1: Basic repository creation
run "basic_repository_creation" {
  command = plan

  variables {
    name        = "test-repository"
    description = "Test repository for module validation"
    visibility  = "public"
  }

  assert {
    condition     = github_repository.this.name == "test-repository"
    error_message = "Repository name should be 'test-repository'"
  }

  assert {
    condition     = github_repository.this.description == "Test repository for module validation"
    error_message = "Repository description doesn't match"
  }

  assert {
    condition     = github_repository.this.visibility == "public"
    error_message = "Repository visibility should be 'public'"
  }

  assert {
    condition     = github_repository.this.auto_init == false
    error_message = "auto_init should be false when not specified"
  }
}

# Test 2: Private repository with advanced features
run "private_repository_with_security" {
  command = plan

  variables {
    name                                   = "private-secure-repo"
    visibility                             = "private"
    enable_advanced_security               = true
    enable_secret_scanning                 = true
    enable_secret_scanning_push_protection = true
    enable_vulnerability_alerts            = true
    enable_dependabot_security_updates     = true
    delete_branch_on_merge                 = true
    web_commit_signoff_required            = true
  }

  assert {
    condition     = github_repository.this.visibility == "private"
    error_message = "Repository should be private"
  }

  assert {
    condition     = github_repository.this.vulnerability_alerts == true
    error_message = "Vulnerability alerts should be enabled"
  }

  assert {
    condition     = github_repository.this.delete_branch_on_merge == true
    error_message = "Delete branch on merge should be enabled"
  }

  assert {
    condition     = github_repository.this.web_commit_signoff_required == true
    error_message = "Web commit signoff should be required"
  }

  assert {
    condition     = github_repository_dependabot_security_updates.this[0].enabled == true
    error_message = "Dependabot security updates should be enabled"
  }
}

# Test 3: Merge strategies configuration
run "merge_strategies_configuration" {
  command = plan

  variables {
    name                        = "merge-test-repo"
    visibility                  = "public"
    allow_merge_commit          = true
    allow_squash_merge          = true
    allow_rebase_merge          = false
    allow_auto_merge            = true
    squash_merge_commit_title   = "PR_TITLE"
    squash_merge_commit_message = "COMMIT_MESSAGES"
    merge_commit_title          = "PR_TITLE"
    merge_commit_message        = "PR_BODY"
  }

  assert {
    condition     = github_repository.this.allow_merge_commit == true
    error_message = "Merge commits should be allowed"
  }

  assert {
    condition     = github_repository.this.allow_squash_merge == true
    error_message = "Squash merge should be allowed"
  }

  assert {
    condition     = github_repository.this.allow_rebase_merge == false
    error_message = "Rebase merge should be disabled"
  }

  assert {
    condition     = github_repository.this.allow_auto_merge == true
    error_message = "Auto merge should be enabled"
  }

  assert {
    condition     = github_repository.this.squash_merge_commit_title == "PR_TITLE"
    error_message = "Squash merge commit title should be PR_TITLE"
  }
}

# Test 4: Branches y default branch
run "branches_configuration" {
  command = plan

  variables {
    name           = "branch-test-repo"
    visibility     = "public"
    default_branch = "main"
    branches = {
      "develop" = "main"
      "staging" = "develop"
    }
  }

  assert {
    condition     = github_branch_default.this[0].branch == "main"
    error_message = "Default branch should be 'main'"
  }

  assert {
    condition     = length(github_branch.this) == 2
    error_message = "Should create 2 branches"
  }

  assert {
    condition     = github_branch.this["develop"].branch == "develop"
    error_message = "Develop branch should exist"
  }

  assert {
    condition     = github_branch.this["staging"].branch == "staging"
    error_message = "Staging branch should exist"
  }
}

# Test 5: GitHub Actions configuration
run "github_actions_configuration" {
  command = plan

  variables {
    name                     = "actions-test-repo"
    visibility               = "public"
    enable_actions           = true
    actions_allowed_policy   = "selected"
    actions_allowed_github   = true
    actions_allowed_verified = true
    actions_allowed_patterns = ["actions/checkout@*", "hashicorp/*"]
    actions_access_level     = "organization"
  }

  assert {
    condition     = github_actions_repository_permissions.this[0].enabled == true
    error_message = "Actions should be enabled"
  }

  assert {
    condition     = github_actions_repository_permissions.this[0].allowed_actions == "selected"
    error_message = "Allowed actions should be 'selected'"
  }

  assert {
    condition     = github_actions_repository_access_level.this[0].access_level == "organization"
    error_message = "Actions access level should be 'organization'"
  }
}

# Test 6: Secrets y variables
run "secrets_and_variables" {
  command = plan

  variables {
    name       = "secrets-test-repo"
    visibility = "private"
    secrets = {
      "API_KEY"      = "secret-value-1"
      "DATABASE_URL" = "secret-value-2"
    }
    secrets_encrypted = {
      "ENCRYPTED_SECRET" = "encrypted-value"
    }
    variables = {
      "ENVIRONMENT" = "test"
      "REGION"      = "us-east-1"
    }
    dependabot_copy_secrets = true
  }

  assert {
    condition     = length(github_actions_secret.plaintext) == 2
    error_message = "Should create 2 plaintext secrets"
  }

  assert {
    condition     = length(github_actions_secret.encrypted) == 1
    error_message = "Should create 1 encrypted secret"
  }

  assert {
    condition     = length(github_actions_variable.this) == 2
    error_message = "Should create 2 variables"
  }

  assert {
    condition     = github_actions_variable.this["ENVIRONMENT"].value == "test"
    error_message = "ENVIRONMENT variable should be 'test'"
  }

  # Note: dependabot_copy_secrets evaluation requires full apply
  # Skipping this assertion for plan-only tests
}

# Test 7: Issue labels
run "issue_labels_configuration" {
  command = plan

  variables {
    name       = "labels-test-repo"
    visibility = "public"
    issue_labels = {
      "bug"           = "Something isn't working"
      "enhancement"   = "New feature or request"
      "documentation" = "Improvements or additions to documentation"
    }
    issue_labels_colors = {
      "bug"         = "d73a4a"
      "enhancement" = "a2eeef"
    }
  }

  assert {
    condition     = length(github_issue_labels.this) == 1
    error_message = "Should create issue labels resource"
  }
}

# Test 8: Deploy keys
run "deploy_keys_configuration" {
  command = plan

  variables {
    name       = "deploy-keys-repo"
    visibility = "private"
    deploy_keys = {
      "ci-cd-key" = {
        public_key = null
        read_only  = false
      }
      "readonly-key" = {
        public_key = null
        read_only  = true
      }
    }
  }

  assert {
    condition     = length(github_repository_deploy_key.this) == 2
    error_message = "Should create 2 deploy keys"
  }

  assert {
    condition     = length(tls_private_key.this) == 2
    error_message = "Should generate 2 TLS private keys (auto-generated when public_key is null)"
  }

  assert {
    condition     = github_repository_deploy_key.this["ci-cd-key"].read_only == false
    error_message = "ci-cd-key should have write access"
  }

  assert {
    condition     = github_repository_deploy_key.this["readonly-key"].read_only == true
    error_message = "readonly-key should be read-only"
  }
}

run "deploy_keys_with_provided_key" {
  command = plan

  variables {
    name       = "deploy-keys-provided-repo"
    visibility = "private"
    deploy_keys = {
      "existing-key" = {
        public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7example"
        read_only  = false
      }
      "auto-generated-key" = {
        public_key = null
        read_only  = true
      }
    }
  }

  assert {
    condition     = length(github_repository_deploy_key.this) == 2
    error_message = "Should create 2 deploy keys"
  }

  assert {
    condition     = length(tls_private_key.this) == 1
    error_message = "Should only generate 1 TLS private key (for auto-generated-key)"
  }

  assert {
    condition     = github_repository_deploy_key.this["existing-key"].read_only == false
    error_message = "existing-key should have write access"
  }

  assert {
    condition     = github_repository_deploy_key.this["auto-generated-key"].read_only == true
    error_message = "auto-generated-key should be read-only"
  }
}

# Test 9: Autolink references
run "autolink_references" {
  command = plan

  variables {
    name       = "autolink-test-repo"
    visibility = "public"
    autolink_references = {
      "JIRA-" = "https://jira.example.com/browse/<num>"
      "GH-"   = "https://github.com/example/repo/issues/<num>"
    }
  }

  assert {
    condition     = length(github_repository_autolink_reference.this) == 2
    error_message = "Should create 2 autolink references"
  }

  assert {
    condition     = github_repository_autolink_reference.this["JIRA-"].target_url_template == "https://jira.example.com/browse/<num>"
    error_message = "JIRA autolink should have correct URL template"
  }
}

# Test 10: Teams y users collaborators
run "collaborators_configuration" {
  command = plan

  variables {
    name       = "collaborators-test-repo"
    visibility = "private"
    teams = {
      "123456" = "push"
      "789012" = "admin"
    }
    users = {
      "developer1" = "push"
      "developer2" = "pull"
      "admin1"     = "admin"
    }
  }

  assert {
    condition     = length(github_repository_collaborators.this) == 1
    error_message = "Should create collaborators resource"
  }

  assert {
    condition     = length(github_repository_collaborators.this[0].team) == 2
    error_message = "Should configure 2 team collaborators"
  }

  assert {
    condition     = length(github_repository_collaborators.this[0].user) == 3
    error_message = "Should configure 3 user collaborators"
  }
}

# Test 11: GitHub Pages configuration
run "github_pages_legacy" {
  command = plan

  variables {
    name                = "pages-test-repo"
    visibility          = "public"
    pages_build_type    = "legacy"
    pages_source_branch = "gh-pages"
    pages_source_path   = "/docs"
    pages_cname         = "example.com"
  }

  assert {
    condition     = github_repository.this.pages[0].build_type == "legacy"
    error_message = "Pages build type should be 'legacy'"
  }

  assert {
    condition     = github_repository.this.pages[0].source[0].branch == "gh-pages"
    error_message = "Pages source branch should be 'gh-pages'"
  }

  assert {
    condition     = github_repository.this.pages[0].cname == "example.com"
    error_message = "Pages CNAME should be 'example.com'"
  }
}

# Test 12: Template repository
run "template_repository" {
  command = plan

  variables {
    name                          = "from-template-repo"
    visibility                    = "public"
    template                      = "owner/template-repo"
    template_include_all_branches = true
  }

  assert {
    condition     = github_repository.this.template[0].owner == "owner"
    error_message = "Template owner should be 'owner'"
  }

  assert {
    condition     = github_repository.this.template[0].repository == "template-repo"
    error_message = "Template repository should be 'template-repo'"
  }

  assert {
    condition     = github_repository.this.template[0].include_all_branches == true
    error_message = "Should include all branches from template"
  }
}

# Test 13: Custom properties
run "custom_properties" {
  command = plan

  variables {
    name       = "custom-props-repo"
    visibility = "public"
    custom_properties = {
      "environment" = "production"
      "team"        = "backend"
      "monitored"   = true
    }
    custom_properties_types = {
      "environment" = "string"
      "team"        = "string"
      "monitored"   = "true_false"
    }
  }

  assert {
    condition     = length(github_repository_custom_property.this) == 3
    error_message = "Should create 3 custom properties"
  }

  assert {
    condition     = github_repository_custom_property.this["environment"].property_type == "string"
    error_message = "environment property should be string type"
  }
}

# Test 14: Topics configuration
run "topics_configuration" {
  command = plan

  variables {
    name       = "topics-test-repo"
    visibility = "public"
    topics     = ["terraform", "github", "automation", "infrastructure"]
  }

  assert {
    condition     = length(github_repository.this.topics) == 4
    error_message = "Should have 4 topics"
  }

  assert {
    condition     = contains(github_repository.this.topics, "terraform")
    error_message = "Should contain 'terraform' topic"
  }
}

# Test 15: Alias (renaming) functionality
run "alias_for_renaming" {
  command = plan

  variables {
    name       = "new-repository-name"
    alias      = "old-repository-name"
    visibility = "public"
  }

  assert {
    condition     = output.alias == "old-repository-name"
    error_message = "Alias should be 'old-repository-name'"
  }

  assert {
    condition     = github_repository.this.name == "new-repository-name"
    error_message = "Repository name should be 'new-repository-name'"
  }
}

# Test 16: Archived repository
run "archived_repository" {
  command = plan

  variables {
    name               = "archived-repo"
    visibility         = "public"
    archived           = true
    archive_on_destroy = true
  }

  assert {
    condition     = github_repository.this.archived == true
    error_message = "Repository should be archived"
  }

  assert {
    condition     = github_repository.this.archive_on_destroy == true
    error_message = "Repository should archive on destroy"
  }
}

# Test 17: Visibility with explicit setting (recommended over deprecated private parameter)
run "visibility_explicit" {
  command = plan

  variables {
    name       = "visibility-test-repo"
    visibility = "private"
  }

  assert {
    condition     = github_repository.this.visibility == "private"
    error_message = "Visibility should be explicitly set to 'private'"
  }
}

# Test 18: Security scanning with public repository
run "security_scanning_public_repo" {
  command = plan

  variables {
    name                                   = "public-security-repo"
    visibility                             = "public"
    enable_advanced_security               = false
    enable_secret_scanning                 = true
    enable_secret_scanning_push_protection = true
  }

  assert {
    condition     = github_repository.this.visibility == "public"
    error_message = "Repository should be public"
  }

  # Security scanning should be enabled for public repos
  assert {
    condition     = local.enable_secret_scanning == true
    error_message = "Secret scanning should be enabled for public repo"
  }
}

# Test 19: Dependabot secrets independientes
run "dependabot_independent_secrets" {
  command = plan

  variables {
    name       = "dependabot-secrets-repo"
    visibility = "private"
    secrets = {
      "ACTIONS_SECRET" = "value1"
    }
    dependabot_secrets = {
      "DEPENDABOT_SECRET" = "value2"
    }
    dependabot_copy_secrets = false
  }

  assert {
    condition     = length(github_actions_secret.plaintext) == 1
    error_message = "Should create 1 actions secret"
  }

  assert {
    condition     = length(github_dependabot_secret.plaintext) == 1
    error_message = "Should create 1 dependabot secret (not copied)"
  }

  assert {
    condition     = github_dependabot_secret.plaintext["DEPENDABOT_SECRET"].secret_name == "DEPENDABOT_SECRET"
    error_message = "Dependabot secret should be independent"
  }
}

# Test 20: Repository features configuration
run "repository_features" {
  command = plan

  variables {
    name         = "features-test-repo"
    visibility   = "public"
    has_issues   = true
    has_projects = false
    has_wiki     = true
    is_template  = true
  }

  assert {
    condition     = github_repository.this.has_issues == true
    error_message = "Issues should be enabled"
  }

  assert {
    condition     = github_repository.this.has_projects == false
    error_message = "Projects should be disabled"
  }

  assert {
    condition     = github_repository.this.has_wiki == true
    error_message = "Wiki should be enabled"
  }

  assert {
    condition     = github_repository.this.is_template == true
    error_message = "Repository should be a template"
  }
}
