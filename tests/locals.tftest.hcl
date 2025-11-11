mock_provider "github" {}

override_data {
  target = data.github_repositories.all[0]
  values = {
    names    = []
    repo_ids = []
  }
}

override_data {
  target = data.github_organization.this[0]
  values = {
    plan = "enterprise"
  }
}

run "test_is_project_mode_organization" {
  command = plan

  variables {
    mode         = "organization"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }
  }

  assert {
    condition     = local.is_project_mode == false
    error_message = "is_project_mode should be false when mode is 'organization'"
  }

  assert {
    condition     = local.spec == "%s"
    error_message = "spec should be '%s' in organization mode"
  }

  assert {
    condition     = local.github_org == "test-org"
    error_message = "github_org should match name in organization mode"
  }
}

run "test_is_project_mode_project" {
  command = plan

  variables {
    mode         = "project"
    name         = "test-project"
    github_org   = "parent-org"
    spec         = "prefix-%s"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }
  }

  assert {
    condition     = local.is_project_mode == true
    error_message = "is_project_mode should be true when mode is 'project'"
  }

  assert {
    condition     = local.spec == "prefix-%s"
    error_message = "spec should be sanitized in project mode"
  }

  assert {
    condition     = local.github_org == "parent-org"
    error_message = "github_org should use var.github_org in project mode"
  }
}

run "test_empty_settings_has_all_keys" {
  command = plan

  variables {
    mode         = "organization"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }
  }

  assert {
    condition = alltrue([
      for key in local.coalesce_keys : contains(keys(local.empty_settings), key)
    ])
    error_message = "empty_settings should contain all coalesce_keys"
  }

  assert {
    condition = alltrue([
      for key in local.merge_keys : contains(keys(local.empty_settings), key)
    ])
    error_message = "empty_settings should contain all merge_keys"
  }

  assert {
    condition = alltrue([
      for key in local.union_keys : contains(keys(local.empty_settings), key)
    ])
    error_message = "empty_settings should contain all union_keys"
  }
}

run "test_repository_merge_basic" {
  command = plan

  variables {
    mode       = "organization"
    name       = "test-org"
    github_org = "test-org"

    settings = {
      billing_email = "test@example.com"
      visibility    = "private"
    }

    repositories = {
      "test-repo" = {
        description = "Test repository"
      }
    }
  }

  assert {
    condition     = contains(keys(local.repositories), "test-repo")
    error_message = "Repository should be present in local.repositories"
  }

  assert {
    condition     = local.repositories["test-repo"].description == "Test repository"
    error_message = "Repository description should be preserved"
  }
}
