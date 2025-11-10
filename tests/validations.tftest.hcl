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

run "test_mode_validation_invalid" {
  command = plan

  variables {
    mode         = "invalid-mode"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }
  }

  expect_failures = [
    var.mode
  ]
}

run "test_mode_validation_organization" {
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
    condition     = var.mode == "organization"
    error_message = "Mode 'organization' should be valid"
  }
}

run "test_mode_validation_project" {
  command = plan

  variables {
    mode         = "project"
    name         = "test-project"
    github_org   = "parent-org"
    spec         = "project-%s"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }
  }

  assert {
    condition     = var.mode == "project"
    error_message = "Mode 'project' should be valid"
  }
}

run "test_secrets_plaintext_deprecated" {
  command = plan

  variables {
    mode         = "organization"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }

    secrets = {
      "TEST_SECRET" = "plaintext-value"
    }
  }

  expect_failures = [
    var.secrets
  ]
}

run "test_dependabot_secrets_plaintext_deprecated" {
  command = plan

  variables {
    mode         = "organization"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }

    dependabot_secrets = {
      "TEST_SECRET" = "plaintext-value"
    }
  }

  expect_failures = [
    var.dependabot_secrets
  ]
}

run "test_webhook_requires_secret" {
  command = plan

  variables {
    mode         = "organization"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }

    webhooks = {
      "test-webhook" = {
        url          = "https://example.com/webhook"
        content_type = "json"
        events       = ["push"]
        # Missing secret
      }
    }
  }

  expect_failures = [
    var.webhooks
  ]
}

run "test_webhook_warns_on_http" {
  command = plan

  variables {
    mode         = "organization"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }

    webhooks = {
      "test-webhook" = {
        url          = "http://example.com/webhook" # HTTP instead of HTTPS
        content_type = "json"
        secret       = "test-secret"
        events       = ["push"]
      }
    }
  }

  expect_failures = [
    var.webhooks
  ]
}

run "test_webhook_valid_https" {
  command = plan

  variables {
    mode         = "organization"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }

    webhooks = {
      "test-webhook" = {
        url          = "https://example.com/webhook"
        content_type = "json"
        secret       = "test-secret"
        events       = ["push"]
      }
    }
  }

  assert {
    condition     = length(var.webhooks) == 1
    error_message = "Valid webhook configuration should pass validation"
  }
}

run "test_runner_groups_selected_without_repositories" {
  command = plan

  variables {
    mode         = "organization"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }

    runner_groups = {
      "test-group" = {
        visibility = "selected"
        # Missing repositories list
      }
    }
  }

  expect_failures = [
    check.runner_groups_validation
  ]
}

run "test_runner_groups_valid_selected" {
  command = plan

  variables {
    mode         = "organization"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    settings = {
      billing_email = "test@example.com"
    }

    runner_groups = {
      "test-group" = {
        visibility   = "selected"
        repositories = ["repo1", "repo2"]
      }
    }
  }

  assert {
    condition     = length(var.runner_groups) == 1
    error_message = "Valid runner group with selected visibility and repositories should pass"
  }
}

run "test_repository_visibility_invalid" {
  command = plan

  variables {
    mode       = "organization"
    name       = "test-org"
    github_org = "test-org"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "test-repo" = {
        visibility = "invalid-visibility"
      }
    }
  }

  expect_failures = [
    var.repositories
  ]
}

run "test_repository_visibility_valid" {
  command = plan

  variables {
    mode       = "organization"
    name       = "test-org"
    github_org = "test-org"

    settings = {
      billing_email = "test@example.com"
    }

    repositories = {
      "private-repo" = {
        visibility = "private"
      }
      "public-repo" = {
        visibility = "public"
      }
      "internal-repo" = {
        visibility = "internal"
      }
    }
  }

  assert {
    condition     = length(var.repositories) == 3
    error_message = "All valid visibility values should pass validation"
  }
}
