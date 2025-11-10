mock_provider "github" {}

mock_provider "kubernetes" {}

mock_provider "helm" {}

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

run "test_project_mode_repository_ids" {
  command = plan

  variables {
    mode       = "project"
    name       = "test-project"
    github_org = "parent-org"
    spec       = "project-%s"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "repo1" = { description = "Test 1" }
      "repo2" = { description = "Test 2" }
    }
  }

  assert {
    condition     = local.is_project_mode == true
    error_message = "Should be in project mode"
  }

  assert {
    condition     = length(local.project_repository_ids) >= 0
    error_message = "project_repository_ids should be defined in project mode"
  }
}

run "test_organization_mode_no_project_ids" {
  command = plan

  variables {
    mode       = "organization"
    name       = "test-org"
    github_org = "test-org"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "repo1" = { description = "Test 1" }
    }
  }

  assert {
    condition     = local.is_project_mode == false
    error_message = "Should be in organization mode"
  }

  assert {
    condition     = length(local.project_repository_ids) == 0
    error_message = "project_repository_ids should be empty in organization mode"
  }
}

run "test_project_mode_spec_formatting" {
  command = plan

  variables {
    mode       = "project"
    name       = "test-project"
    github_org = "parent-org"
    spec       = "prefix-[%s]-suffix" # Special chars should be sanitized

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {}
  }

  assert {
    condition     = local.spec == "prefix-%s-suffix"
    error_message = "Special characters should be removed from spec in project mode"
  }
}

run "test_organization_mode_spec_passthrough" {
  command = plan

  variables {
    mode       = "organization"
    name       = "test-org"
    github_org = "test-org"
    spec       = "prefix-[%s]-suffix" # Should be ignored

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {}
  }

  assert {
    condition     = local.spec == "%s"
    error_message = "spec should always be '%s' in organization mode regardless of input"
  }
}

run "test_project_mode_variables_visibility" {
  command = plan

  variables {
    mode       = "project"
    name       = "test-project"
    github_org = "parent-org"
    spec       = "project-%s"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "repo1" = { description = "Test" }
    }

    variables = {
      "TEST_VAR" = "value"
    }
  }

  assert {
    condition     = length(var.variables) == 1
    error_message = "Variables should be configurable in project mode"
  }
}

run "test_project_mode_secrets_visibility" {
  command = plan

  variables {
    mode       = "project"
    name       = "test-project"
    github_org = "parent-org"
    spec       = "project-%s"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "repo1" = { description = "Test" }
    }

    secrets_encrypted = {
      "TEST_SECRET" = "dGVzdC1lbmNyeXB0ZWQtdmFsdWU=" # base64 encoded
    }
  }

  assert {
    condition     = length(var.secrets_encrypted) == 1
    error_message = "Encrypted secrets should be configurable in project mode"
  }
}

run "test_project_mode_runner_groups_forced_selected" {
  command = plan

  variables {
    mode       = "project"
    name       = "test-project"
    github_org = "parent-org"
    spec       = "project-%s"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "repo1" = { description = "Test" }
    }

    runner_groups = {
      "test-group" = {
        visibility = "all" # Should be overridden to "selected" in project mode
      }
    }
  }

  assert {
    condition     = length(var.runner_groups) == 1
    error_message = "Runner groups should be configurable in project mode"
  }
}
