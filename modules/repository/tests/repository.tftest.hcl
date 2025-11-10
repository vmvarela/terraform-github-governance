# Native Terraform HCL tests to validate configuration logic
# These tests run in "plan" mode and validate structure without making actual GitHub API calls

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
