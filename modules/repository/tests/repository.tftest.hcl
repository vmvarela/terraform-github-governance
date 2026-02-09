# Native Terraform HCL tests to validate configuration logic
# These tests run in "plan" mode and validate structure without making actual GitHub API calls

mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      id         = "test-repo-id"
      name       = "test-repo"
      full_name  = "test-org/test-repo"
      html_url   = "https://github.com/test-org/test-repo"
      visibility = "private"
    }
  }

  mock_resource "github_repository_environment" {
    defaults = {
      id          = "test-env-id"
      environment = "staging"
    }
  }

  mock_resource "github_repository_ruleset" {
    defaults = {
      id   = 123
      name = "protected-branches"
    }
  }

  mock_resource "github_branch_default" {
    defaults = {
      id = "test-repo"
    }
  }
}

run "basic_repository" {
  command = plan
  variables {
    name                 = "repo-basic"
    description          = "Basic repo"
    visibility           = "private"
    default_branch       = "main"
    organization         = "test-org"
    topics               = []
    permissions          = {}
    deploy_keys          = {}
    webhooks             = {}
    repository_secrets   = {}
    repository_variables = {}
    environments         = {}
    protected_branches   = []
    github_team_ids      = {}
    github_user_ids      = {}
    github_app_ids       = {}
  }
  assert {
    condition     = github_repository.this.name == "repo-basic"
    error_message = "Name mismatch"
  }
  assert {
    condition     = github_repository.this.visibility == "private"
    error_message = "Visibility mismatch"
  }
}

run "environments_with_reviewers" {
  command = plan
  variables {
    name                 = "repo-envs"
    description          = "Envs with reviewers"
    visibility           = "private"
    default_branch       = "main"
    organization         = "test-org"
    topics               = []
    permissions          = {}
    deploy_keys          = {}
    webhooks             = {}
    repository_secrets   = {}
    repository_variables = {}
    protected_branches   = []
    environments = {
      staging = {
        secrets   = { STAGE_TOKEN = "s" }
        variables = { DEBUG = "true" }
      }
      production = {
        required_approvers = ["team:admins"]
        secrets            = { PROD_TOKEN = "p" }
        variables          = { DEBUG = "false" }
      }
    }
    github_team_ids = { admins = 12345 }
    github_user_ids = {}
    github_app_ids  = {}
  }
  assert {
    condition     = length(github_repository_environment.env) == 2
    error_message = "Should create 2 environments"
  }
}

run "ruleset_with_bypass" {
  command = plan
  variables {
    name                    = "repo-ruleset"
    description             = "Ruleset test"
    visibility              = "private"
    default_branch          = "main"
    organization            = "test-org"
    topics                  = []
    permissions             = {}
    deploy_keys             = {}
    webhooks                = {}
    repository_secrets      = {}
    repository_variables    = {}
    environments            = {}
    protected_branches      = ["main"]
    allow_bypass            = ["org-admin", "team:platform"]
    github_team_ids         = { platform = 12345 }
    github_user_ids         = {}
    github_app_ids          = {}
    required_approvals      = 1
    prevent_force_push      = true
    prevent_branch_deletion = true
  }
  assert {
    condition     = length(github_repository_ruleset.ruleset) == 1
    error_message = "Ruleset should exist"
  }
  assert {
    condition     = github_repository_ruleset.ruleset[0].name == "protected-branches"
    error_message = "Ruleset name mismatch"
  }
}

run "repository_with_merge_settings" {
  command = plan
  variables {
    name                   = "repo-merge"
    description            = "Merge settings test"
    visibility             = "private"
    default_branch         = "main"
    organization           = "test-org"
    topics                 = []
    permissions            = {}
    deploy_keys            = {}
    webhooks               = {}
    repository_secrets     = {}
    repository_variables   = {}
    environments           = {}
    protected_branches     = []
    github_team_ids        = {}
    github_user_ids        = {}
    github_app_ids         = {}
    allow_merge_commit     = false
    allow_squash_merge     = true
    allow_rebase_merge     = false
    delete_branch_on_merge = true
    allow_auto_merge       = true
  }
  assert {
    condition     = github_repository.this.allow_merge_commit == false
    error_message = "allow_merge_commit should be false"
  }
  assert {
    condition     = github_repository.this.allow_squash_merge == true
    error_message = "allow_squash_merge should be true"
  }
  assert {
    condition     = github_repository.this.allow_rebase_merge == false
    error_message = "allow_rebase_merge should be false"
  }
  assert {
    condition     = github_repository.this.delete_branch_on_merge == true
    error_message = "delete_branch_on_merge should be true"
  }
  assert {
    condition     = github_repository.this.allow_auto_merge == true
    error_message = "allow_auto_merge should be true"
  }
}

run "repository_with_feature_toggles" {
  command = plan
  variables {
    name                 = "repo-features"
    description          = "Feature toggles test"
    visibility           = "private"
    default_branch       = "main"
    organization         = "test-org"
    topics               = []
    permissions          = {}
    deploy_keys          = {}
    webhooks             = {}
    repository_secrets   = {}
    repository_variables = {}
    environments         = {}
    protected_branches   = []
    github_team_ids      = {}
    github_user_ids      = {}
    github_app_ids       = {}
    has_issues           = true
    has_wiki             = false
    has_projects         = false
    has_discussions      = true
  }
  assert {
    condition     = github_repository.this.has_issues == true
    error_message = "has_issues should be true"
  }
  assert {
    condition     = github_repository.this.has_wiki == false
    error_message = "has_wiki should be false"
  }
  assert {
    condition     = github_repository.this.has_projects == false
    error_message = "has_projects should be false"
  }
  assert {
    condition     = github_repository.this.has_discussions == true
    error_message = "has_discussions should be true"
  }
}
