# Tests for webhook resources (adapted from modules/repository)
# Tests now use the main module with composite keys for webhooks

mock_provider "github" {}
mock_provider "tls" {}
mock_provider "null" {}
mock_provider "local" {}

variables {
  mode       = "organization"
  name       = "test-org"
  github_org = "test-org"
  settings = {
    billing_email = "billing@test-org.com"
  }
}

# Test 1: Basic webhook
run "basic_webhook" {
  command = plan

  variables {
    repositories = {
      "webhook-repo" = {
        description = "Repository with basic webhook"
        webhooks = {
          "basic-webhook" = {
            url          = "https://example.com/webhook"
            content_type = "json"
            events       = ["push", "pull_request"]
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_webhook.repo : k => v if startswith(k, "webhook-repo/") })) == 1
    error_message = "Should create 1 webhook"
  }

  assert {
    condition     = github_repository_webhook.repo["webhook-repo/basic-webhook"].configuration[0].url == "https://example.com/webhook"
    error_message = "Webhook URL should match"
  }
}

# Test 2: Webhook with JSON content type
run "webhook_json_content_type" {
  command = plan

  variables {
    repositories = {
      "json-webhook-repo" = {
        description = "Repository with JSON webhook"
        webhooks = {
          "json-webhook" = {
            url          = "https://api.example.com/github"
            events       = ["issues", "issue_comment"]
            content_type = "json"
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_webhook.repo["json-webhook-repo/json-webhook"].configuration[0].content_type == "json"
    error_message = "Webhook should have JSON content type"
  }
}

# Test 3: Webhook with form content type (default)
run "webhook_form_content_type" {
  command = plan

  variables {
    repositories = {
      "form-webhook-repo" = {
        description = "Repository with form webhook"
        webhooks = {
          "form-webhook" = {
            url          = "https://example.com/webhook"
            events       = ["push"]
            content_type = "form"
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_webhook.repo["form-webhook-repo/form-webhook"].configuration[0].content_type == "form"
    error_message = "Webhook should have form content type"
  }
}

# Test 4: Webhook with secret
run "webhook_with_secret" {
  command = plan

  variables {
    repositories = {
      "secure-webhook-repo" = {
        description = "Repository with secured webhook"
        webhooks = {
          "secure-webhook" = {
            url          = "https://example.com/webhook"
            content_type = "json"
            events       = ["push"]
            secret       = "my-webhook-secret-token"
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_webhook.repo : k => v if startswith(k, "secure-webhook-repo/") })) == 1
    error_message = "Webhook should be created with secret"
  }
}

# Test 5: Webhook with insecure SSL
run "webhook_insecure_ssl" {
  command = plan

  variables {
    repositories = {
      "insecure-webhook-repo" = {
        description = "Repository with insecure SSL webhook"
        webhooks = {
          "insecure-webhook" = {
            url          = "https://internal.example.com/webhook"
            content_type = "json"
            events       = ["push"]
            insecure_ssl = true
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_webhook.repo["insecure-webhook-repo/insecure-webhook"].configuration[0].insecure_ssl == true
    error_message = "Webhook should allow insecure SSL"
  }
}

# Test 6: Webhook with verified SSL
run "webhook_secure_ssl" {
  command = plan

  variables {
    repositories = {
      "verified-ssl-repo" = {
        description = "Repository with verified SSL webhook"
        webhooks = {
          "verified-ssl-webhook" = {
            url          = "https://example.com/webhook"
            content_type = "json"
            events       = ["push"]
            insecure_ssl = false
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_webhook.repo["verified-ssl-repo/verified-ssl-webhook"].configuration[0].insecure_ssl == false
    error_message = "Webhook should require verified SSL"
  }
}

# Test 7: Multiple webhooks in one repository
run "multiple_webhooks" {
  command = plan

  variables {
    repositories = {
      "multi-webhook-repo" = {
        description = "Repository with multiple webhooks"
        webhooks = {
          "ci-webhook" = {
            url          = "https://ci.example.com/github"
            content_type = "json"
            events       = ["push", "pull_request"]
          }
          "monitoring-webhook" = {
            url          = "https://monitoring.example.com/events"
            events       = ["issues", "issue_comment", "pull_request_review"]
            content_type = "json"
          }
          "deploy-webhook" = {
            url          = "https://deploy.example.com/webhook"
            content_type = "json"
            events       = ["release", "deployment"]
            secret       = "deploy-secret"
          }
        }
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_webhook.repo : k => v if startswith(k, "multi-webhook-repo/") })) == 3
    error_message = "Should create 3 webhooks"
  }
}

# Test 8: Webhook with many events
run "webhook_all_events" {
  command = plan

  variables {
    repositories = {
      "all-events-repo" = {
        description = "Repository with comprehensive event webhook"
        webhooks = {
          "all-events-webhook" = {
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
        }
      }
    }
  }

  assert {
    condition     = length(github_repository_webhook.repo["all-events-repo/all-events-webhook"].events) > 20
    error_message = "Webhook should have many events"
  }
}

# Test 9: Webhook for push only
run "webhook_push_only" {
  command = plan

  variables {
    repositories = {
      "push-webhook-repo" = {
        description = "Repository with push-only webhook"
        webhooks = {
          "push-webhook" = {
            url          = "https://ci.example.com/build"
            content_type = "json"
            events       = ["push"]
          }
        }
      }
    }
  }

  assert {
    condition     = contains(github_repository_webhook.repo["push-webhook-repo/push-webhook"].events, "push")
    error_message = "Webhook should include push event"
  }
}

# Test 10: Complete CI/CD webhook
run "webhook_cicd_complete" {
  command = plan

  variables {
    repositories = {
      "cicd-repo" = {
        description = "Repository with complete CI/CD webhook"
        webhooks = {
          "cicd-webhook" = {
            url          = "https://ci.example.com/github-webhook"
            events       = ["push", "pull_request", "pull_request_review", "status", "check_run", "check_suite"]
            content_type = "json"
            secret       = "ci-webhook-secret-key"
            insecure_ssl = false
          }
        }
      }
    }
  }

  assert {
    condition     = github_repository_webhook.repo["cicd-repo/cicd-webhook"].configuration[0].content_type == "json"
    error_message = "CI/CD webhook should use JSON"
  }

  assert {
    condition     = github_repository_webhook.repo["cicd-repo/cicd-webhook"].configuration[0].insecure_ssl == false
    error_message = "CI/CD webhook should require secure SSL"
  }
}

# Test 11: Webhook for issue notifications
run "webhook_issues_notifications" {
  command = plan

  variables {
    repositories = {
      "issues-repo" = {
        description = "Repository with issue notification webhook"
        webhooks = {
          "issues-webhook" = {
            url          = "https://notifications.example.com/issues"
            content_type = "json"
            events       = ["issues", "issue_comment", "label"]
          }
        }
      }
    }
  }

  assert {
    condition     = contains(github_repository_webhook.repo["issues-repo/issues-webhook"].events, "issues")
    error_message = "Webhook should include issues event"
  }

  assert {
    condition     = contains(github_repository_webhook.repo["issues-repo/issues-webhook"].events, "issue_comment")
    error_message = "Webhook should include issue_comment event"
  }
}

# Test 12: Webhook for deployment automation
run "webhook_deployment_automation" {
  command = plan

  variables {
    repositories = {
      "deployment-repo" = {
        description = "Repository with deployment webhook"
        webhooks = {
          "deployment-webhook" = {
            url          = "https://deploy.example.com/github"
            events       = ["deployment", "deployment_status", "release"]
            content_type = "json"
            secret       = "deployment-secret"
          }
        }
      }
    }
  }

  assert {
    condition     = contains(github_repository_webhook.repo["deployment-repo/deployment-webhook"].events, "deployment")
    error_message = "Webhook should include deployment event"
  }

  assert {
    condition     = contains(github_repository_webhook.repo["deployment-repo/deployment-webhook"].events, "release")
    error_message = "Webhook should include release event"
  }
}
