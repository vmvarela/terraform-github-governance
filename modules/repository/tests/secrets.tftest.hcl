# Tests for repository secret handling (object form)

run "secrets_object_handling" {
  command = plan

  variables {
    name           = "repo-secrets"
    description    = "Repository with secrets"
    visibility     = "private"
    default_branch = "main"
    organization   = "test-org"
    topics         = []
    permissions    = {}
    deploy_keys    = {}
    webhooks       = {}
    repository_secrets = {
      "CI_TOKEN" = "secret-value"
    }
    repository_variables = {}
    environments         = {}
    protected_branches   = ["main"]
    github_team_ids      = {}
    github_user_ids      = {}
    github_app_ids       = {}
  }

  # Verify that secret resource is declared
  assert {
    condition     = length(github_actions_secret.repo_secret) == 1
    error_message = "Expected one repository secret to be created"
  }

  # Verify secret name
  assert {
    condition     = github_actions_secret.repo_secret["CI_TOKEN"].secret_name == "CI_TOKEN"
    error_message = "Secret name should be CI_TOKEN"
  }
}
