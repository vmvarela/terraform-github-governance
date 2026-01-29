# Test that governance fetches team IDs when github_team_ids is empty

mock_provider "github" {
  mock_resource "github_repository" {
    defaults = {
      id             = "test-repo-id"
      name           = "test-repo"
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

  mock_data "github_organization_teams" {
    defaults = {
      teams = [
        {
          id   = 1
          slug = "test-team"
          name = "Test Team"
        }
      ]
    }
  }
}

run "fetch_team_ids_when_empty" {
  command = plan

  variables {
    organization      = "test-org"
    workspace         = "team-fetch"
    repository_naming = "%s"

    repositories = {
      api = {
        protected_branches = ["main"]
        allow_bypass       = ["team:test-team"]
        description        = "API with team bypass"
      }
    }

    github_team_ids = {}
  }

  assert {
    condition     = module.repositories["api"].protected_branches_ruleset_created
    error_message = "Ruleset should be created even when github_team_ids is empty (data fetch path)"
  }
}
