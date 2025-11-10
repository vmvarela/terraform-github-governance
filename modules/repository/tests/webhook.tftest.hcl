# Tests for webhook module with mock providers

mock_provider "github" {}

variables {
  name       = "test-webhook-repo"
  visibility = "public"
}

# Test 1: Basic webhook
run "basic_webhook" {
  command = plan

  variables {
    webhooks = [
      {
        url    = "https://example.com/webhook"
        events = ["push", "pull_request"]
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Should create 1 webhook"
  }
}

# Test 2: Webhook con content type JSON
run "webhook_json_content_type" {
  command = plan

  variables {
    webhooks = [
      {
        url          = "https://api.example.com/github"
        events       = ["issues", "issue_comment"]
        content_type = "json"
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Should create webhook with JSON content type"
  }
}

# Test 3: Webhook con form content type (default)
run "webhook_form_content_type" {
  command = plan

  variables {
    webhooks = [
      {
        url          = "https://example.com/webhook"
        events       = ["push"]
        content_type = "form"
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Should create webhook with form content type"
  }
}

# Test 4: Webhook con secret
run "webhook_with_secret" {
  command = plan

  variables {
    webhooks = [
      {
        url    = "https://example.com/webhook"
        events = ["push"]
        secret = "my-webhook-secret-token"
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Webhook should be created with secret"
  }
}

# Test 5: Webhook con insecure SSL
run "webhook_insecure_ssl" {
  command = plan

  variables {
    webhooks = [
      {
        url          = "https://internal.example.com/webhook"
        events       = ["push"]
        insecure_ssl = true
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Webhook should be created with insecure SSL"
  }
}

# Test 6: Webhook seguro (SSL verificado)
run "webhook_secure_ssl" {
  command = plan

  variables {
    webhooks = [
      {
        url          = "https://example.com/webhook"
        events       = ["push"]
        insecure_ssl = false
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Webhook should be created with verified SSL"
  }
}

# Test 7: Multiple webhooks
run "multiple_webhooks" {
  command = plan

  variables {
    webhooks = [
      {
        url    = "https://ci.example.com/github"
        events = ["push", "pull_request"]
      },
      {
        url          = "https://monitoring.example.com/events"
        events       = ["issues", "issue_comment", "pull_request_review"]
        content_type = "json"
      },
      {
        url    = "https://deploy.example.com/webhook"
        events = ["release", "deployment"]
        secret = "deploy-secret"
      }
    ]
  }

  assert {
    condition     = length(module.webhook) == 3
    error_message = "Should create 3 webhooks"
  }
}

# Test 8: Webhook con todos los eventos
run "webhook_all_events" {
  command = plan

  variables {
    webhooks = [
      {
        url = "https://example.com/all-events"
        events = [
          "check_run",
          "check_suite",
          "commit_comment",
          "create",
          "delete",
          "deployment",
          "deployment_status",
          "fork",
          "gollum",
          "issue_comment",
          "issues",
          "label",
          "member",
          "milestone",
          "page_build",
          "project",
          "project_card",
          "project_column",
          "public",
          "pull_request",
          "pull_request_review",
          "pull_request_review_comment",
          "push",
          "release",
          "repository",
          "status",
          "watch"
        ]
        content_type = "json"
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Should create webhook with many events"
  }
}

# Test 9: Webhook solo para push
run "webhook_push_only" {
  command = plan

  variables {
    webhooks = [
      {
        url    = "https://ci.example.com/build"
        events = ["push"]
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Should create webhook for push events"
  }
}

# Test 10: Webhook para CI/CD completo
run "webhook_cicd_complete" {
  command = plan

  variables {
    webhooks = [
      {
        url          = "https://ci.example.com/github-webhook"
        events       = ["push", "pull_request", "pull_request_review", "status", "check_run", "check_suite"]
        content_type = "json"
        secret       = "ci-webhook-secret-key"
        insecure_ssl = false
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Should create complete CI/CD webhook"
  }
}

# Test 11: Webhook para notificaciones de issues
run "webhook_issues_notifications" {
  command = plan

  variables {
    webhooks = [
      {
        url    = "https://notifications.example.com/issues"
        events = ["issues", "issue_comment", "label"]
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Should create webhook for issue notifications"
  }
}

# Test 12: Webhook para deployment automation
run "webhook_deployment_automation" {
  command = plan

  variables {
    webhooks = [
      {
        url          = "https://deploy.example.com/github"
        events       = ["deployment", "deployment_status", "release"]
        content_type = "json"
        secret       = "deployment-secret"
      }
    ]
  }

  assert {
    condition     = length(keys(module.webhook)) == 1
    error_message = "Should create webhook for deployment automation"
  }
}
