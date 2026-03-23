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

  mock_resource "github_repository_deploy_key" {
    defaults = {
      id = "test-deploy-key-id"
    }
  }

  mock_resource "github_repository_webhook" {
    defaults = {
      id  = "test-webhook-id"
      url = "https://example.com/hook"
    }
  }

  mock_resource "github_repository_collaborators" {
    defaults = {
      id = "test-collaborators-id"
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

run "deploy_keys_coverage" {
  command = plan
  variables {
    name                 = "repo-deploy-keys"
    description          = "Deploy keys coverage test"
    visibility           = "private"
    default_branch       = "main"
    organization         = "test-org"
    topics               = []
    permissions          = {}
    repository_secrets   = {}
    repository_variables = {}
    environments         = {}
    protected_branches   = []
    github_team_ids      = {}
    github_user_ids      = {}
    github_app_ids       = {}
    webhooks             = {}
    deploy_keys = {
      "ci-bot" = {
        key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC ci-bot"
        read_only = true
      }
      "deploy-key" = {
        key       = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC deploy-key"
        read_only = false
      }
    }
  }
  assert {
    condition     = output.deploy_keys_count == 2
    error_message = "Should create 2 deploy keys"
  }
  assert {
    condition     = github_repository_deploy_key.deploy_key["ci-bot"].read_only == true
    error_message = "ci-bot deploy key should be read_only"
  }
  assert {
    condition     = github_repository_deploy_key.deploy_key["deploy-key"].read_only == false
    error_message = "deploy-key should not be read_only"
  }
}

run "webhooks_coverage" {
  command = plan
  variables {
    name                 = "repo-webhooks"
    description          = "Webhooks coverage test"
    visibility           = "private"
    default_branch       = "main"
    organization         = "test-org"
    topics               = []
    permissions          = {}
    deploy_keys          = {}
    repository_secrets   = {}
    repository_variables = {}
    environments         = {}
    protected_branches   = []
    github_team_ids      = {}
    github_user_ids      = {}
    github_app_ids       = {}
    webhooks = {
      "ci-webhook" = {
        url    = "https://ci.example.com/webhook"
        events = ["push", "pull_request"]
        secret = "mysecret"
      }
      "notify" = {
        url    = "https://notify.example.com/hook"
        events = ["issues"]
      }
    }
  }
  assert {
    condition     = output.webhooks_count == 2
    error_message = "Should create 2 webhooks"
  }
  assert {
    condition     = contains(github_repository_webhook.webhook["ci-webhook"].events, "push")
    error_message = "ci-webhook should listen to push events"
  }
  assert {
    condition     = github_repository_webhook.webhook["notify"].configuration[0].url == "https://notify.example.com/hook"
    error_message = "notify webhook URL mismatch"
  }
}

run "permissions_coverage" {
  command = plan
  variables {
    name                 = "repo-permissions"
    description          = "Permissions coverage test"
    visibility           = "private"
    default_branch       = "main"
    organization         = "test-org"
    topics               = []
    deploy_keys          = {}
    webhooks             = {}
    repository_secrets   = {}
    repository_variables = {}
    environments         = {}
    protected_branches   = []
    github_team_ids      = { platform = 12345 }
    github_user_ids      = { alice = 67890 }
    github_app_ids       = {}
    permissions = {
      "user:alice"    = "push"
      "team:platform" = "admin"
    }
  }
  assert {
    condition     = length(github_repository_collaborators.all) == 1
    error_message = "Should create the collaborators resource when permissions are set"
  }
}

# Auto-elevation tests: verify that environment reviewers are elevated to push
# when they lack the minimum required permission (push/maintain/admin).

run "reviewer_no_explicit_permission_gets_push" {
  command = plan
  variables {
    name                 = "repo-reviewer-no-perm"
    description          = "Reviewer with no explicit permission gets elevated to push"
    visibility           = "private"
    default_branch       = "main"
    organization         = "test-org"
    topics               = []
    deploy_keys          = {}
    webhooks             = {}
    repository_secrets   = {}
    repository_variables = {}
    protected_branches   = []
    github_team_ids      = {}
    github_user_ids      = { alice = 111 }
    github_app_ids       = {}
    permissions          = {}
    environments = {
      staging = {
        required_approvers = ["user:alice"]
      }
    }
  }
  assert {
    condition     = length(github_repository_collaborators.all) == 1
    error_message = "Collaborators resource should be created for auto-elevated reviewer"
  }
  assert {
    condition = tolist([
      for u in github_repository_collaborators.all[0].user :
      u.permission if u.username == "alice"
    ])[0] == "push"
    error_message = "Reviewer with no explicit permission should be elevated to push"
  }
}

run "reviewer_already_has_push_not_changed" {
  command = plan
  variables {
    name                 = "repo-reviewer-push"
    description          = "Reviewer already with push permission is not changed"
    visibility           = "private"
    default_branch       = "main"
    organization         = "test-org"
    topics               = []
    deploy_keys          = {}
    webhooks             = {}
    repository_secrets   = {}
    repository_variables = {}
    protected_branches   = []
    github_team_ids      = {}
    github_user_ids      = { alice = 111 }
    github_app_ids       = {}
    permissions = {
      "user:alice" = "push"
    }
    environments = {
      staging = {
        required_approvers = ["user:alice"]
      }
    }
  }
  assert {
    condition = tolist([
      for u in github_repository_collaborators.all[0].user :
      u.permission if u.username == "alice"
    ])[0] == "push"
    error_message = "Reviewer already with push should remain at push"
  }
}

run "reviewer_with_admin_not_downgraded" {
  command = plan
  variables {
    name                 = "repo-reviewer-admin"
    description          = "Reviewer with admin permission is not downgraded"
    visibility           = "private"
    default_branch       = "main"
    organization         = "test-org"
    topics               = []
    deploy_keys          = {}
    webhooks             = {}
    repository_secrets   = {}
    repository_variables = {}
    protected_branches   = []
    github_team_ids      = {}
    github_user_ids      = { alice = 111 }
    github_app_ids       = {}
    permissions = {
      "user:alice" = "admin"
    }
    environments = {
      staging = {
        required_approvers = ["user:alice"]
      }
    }
  }
  assert {
    condition = tolist([
      for u in github_repository_collaborators.all[0].user :
      u.permission if u.username == "alice"
    ])[0] == "admin"
    error_message = "Reviewer with admin should not be downgraded to push"
  }
}

run "reviewer_with_pull_gets_elevated_to_push" {
  command = plan
  variables {
    name                 = "repo-reviewer-pull"
    description          = "Reviewer with pull permission is elevated to push"
    visibility           = "private"
    default_branch       = "main"
    organization         = "test-org"
    topics               = []
    deploy_keys          = {}
    webhooks             = {}
    repository_secrets   = {}
    repository_variables = {}
    protected_branches   = []
    github_team_ids      = {}
    github_user_ids      = { alice = 111 }
    github_app_ids       = {}
    permissions = {
      "user:alice" = "pull"
    }
    environments = {
      staging = {
        required_approvers = ["user:alice"]
      }
    }
  }
  assert {
    condition = tolist([
      for u in github_repository_collaborators.all[0].user :
      u.permission if u.username == "alice"
    ])[0] == "push"
    error_message = "Reviewer with pull should be elevated to push"
  }
}
