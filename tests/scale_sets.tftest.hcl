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

run "test_scale_set_without_controller" {
  command = plan

  variables {
    mode       = "organization"
    name       = "test-org"
    github_org = "test-org"
    repositories = {
      "repo1" = {
        description = "Test repo 1"
      }
    }

    runner_groups = {
      "test-runners" = {
        visibility = "all"
        scale_set = {
          min_runners = 1
          max_runners = 5
        }
      }
    }

    settings = {
      billing_email = "test@example.com"
    }

    # No actions_runner_controller configured
  }

  # Should not create scale set module when controller is not configured
  assert {
    condition     = length(module.actions_runner_scale_set) == 0
    error_message = "Scale set module should not be created without actions_runner_controller"
  }
}

run "test_scale_set_with_controller_organization_mode" {
  command = plan

  variables {
    mode       = "organization"
    name       = "test-org"
    github_org = "test-org"
    repositories = {
      "repo1" = {
        description = "Test repo 1"
      }
      "repo2" = {
        description = "Test repo 2"
      }
    }

    runner_groups = {
      "prod-runners" = {
        visibility   = "selected"
        repositories = ["repo1", "repo2"]
        scale_set = {
          namespace    = "arc-prod"
          min_runners  = 2
          max_runners  = 10
          runner_image = "ghcr.io/actions/actions-runner:2.311.0"
        }
      }
      "dev-runners" = {
        visibility = "all"
        # No scale_set configured
      }
    }

    actions_runner_controller = {
      name             = "arc-controller"
      namespace        = "arc-systems"
      create_namespace = true
      version          = "0.13.0"
      github_token     = "ghp_test123456789"
    }

    settings = {
      billing_email = "test@example.com"
    }
  }

  # Should create scale set module when controller is configured
  assert {
    condition     = length(module.actions_runner_scale_set) == 1
    error_message = "Scale set module should be created when actions_runner_controller is configured"
  }

  # Verify scale sets outputs
  assert {
    condition     = module.actions_runner_scale_set[0].scale_set_count == 1
    error_message = "Should create exactly 1 scale set (only prod-runners has scale_set configured)"
  }

  assert {
    condition     = contains(module.actions_runner_scale_set[0].scale_set_names, "prod-runners")
    error_message = "prod-runners scale set should be created"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["prod-runners"].min_runners == 2
    error_message = "prod-runners should have min_runners = 2"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["prod-runners"].max_runners == 10
    error_message = "prod-runners should have max_runners = 10"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["prod-runners"].namespace == "arc-prod"
    error_message = "prod-runners should use arc-prod namespace"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].controller.name == "arc-controller"
    error_message = "Controller should be named arc-controller"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].controller_namespace == "arc-systems"
    error_message = "Controller should be in arc-systems namespace"
  }

  # Verify runner groups are created
  assert {
    condition     = length(keys(github_actions_runner_group.this)) == 2
    error_message = "Should create 2 runner groups"
  }

  # Verify prod-runners group exists
  assert {
    condition     = contains(keys(github_actions_runner_group.this), "prod-runners")
    error_message = "Should create prod-runners group"
  }

  # Verify dev-runners group exists
  assert {
    condition     = contains(keys(github_actions_runner_group.this), "dev-runners")
    error_message = "Should create dev-runners group"
  }

  # Verify summary output
  assert {
    condition     = module.actions_runner_scale_set[0].summary.controller_deployed == true
    error_message = "Summary should show controller deployed"
  }

}

run "test_scale_set_project_mode" {
  command = plan

  variables {
    mode       = "project"
    name       = "my-project"
    github_org = "test-org"
    spec       = "my-project-%s"
    repositories = {
      "api" = {
        description = "API service"
      }
      "frontend" = {
        description = "Frontend app"
      }
    }

    runner_groups = {
      "ci-runners" = {
        scale_set = {
          min_runners    = 1
          max_runners    = 3
          container_mode = "kubernetes"
        }
      }
    }

    actions_runner_controller = {
      name                       = "arc"
      namespace                  = "arc-systems"
      create_namespace           = true
      version                    = "0.13.0"
      github_app_id              = 123456
      github_app_private_key     = "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----"
      github_app_installation_id = 789012
    }

    settings = {
      billing_email = "test@example.com"
    }
  }

  # Should create scale set module
  assert {
    condition     = length(module.actions_runner_scale_set) == 1
    error_message = "Scale set module should be created"
  }

  # Verify scale set configuration
  assert {
    condition     = module.actions_runner_scale_set[0].scale_set_count == 1
    error_message = "Should create exactly 1 scale set"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["ci-runners"].container_mode == "kubernetes"
    error_message = "ci-runners should use kubernetes container mode"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["ci-runners"].min_runners == 1
    error_message = "ci-runners should have min_runners = 1"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["ci-runners"].max_runners == 3
    error_message = "ci-runners should have max_runners = 3"
  }

  # Should create runner group with selected visibility (forced in project mode)
  assert {
    condition     = github_actions_runner_group.this["ci-runners"].visibility == "selected"
    error_message = "Runner group visibility should be 'selected' in project mode"
  }

  # Should create ci-runners group
  assert {
    condition     = contains(keys(github_actions_runner_group.this), "ci-runners")
    error_message = "Should create ci-runners group"
  }
}

run "test_scale_set_with_private_registry" {
  command = plan

  variables {
    mode       = "organization"
    name       = "test-org"
    github_org = "test-org"
    repositories = {
      "repo1" = {
        description = "Test repo"
      }
    }

    runner_groups = {
      "custom-runners" = {
        visibility = "all"
        scale_set = {
          runner_image = "myregistry.io/custom-runner:latest"
          pull_always  = true
        }
      }
    }

    actions_runner_controller = {
      github_token              = "ghp_test123456789"
      private_registry          = "myregistry.io"
      private_registry_username = "myuser"
      private_registry_password = "mypassword"
    }

    settings = {
      billing_email = "test@example.com"
    }
  }

  # Should create scale set module with private registry
  assert {
    condition     = length(module.actions_runner_scale_set) == 1
    error_message = "Scale set module should be created with private registry"
  }

  # Verify private registry configuration
  assert {
    condition     = module.actions_runner_scale_set[0].has_private_registry == true
    error_message = "Should indicate private registry is configured"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["custom-runners"].runner_image == "myregistry.io/custom-runner:latest"
    error_message = "Should use custom runner image from private registry"
  }

  # Should create runner group
  assert {
    condition     = contains(keys(github_actions_runner_group.this), "custom-runners")
    error_message = "Should create custom-runners group"
  }
}

run "test_scale_set_shared_namespace" {
  command = plan

  variables {
    mode       = "organization"
    name       = "test-org"
    github_org = "test-org"
    repositories = {
      "repo1" = {
        description = "Test repo"
      }
      "repo2" = {
        description = "Another repo"
      }
    }

    runner_groups = {
      "prod-runners" = {
        visibility = "all"
        scale_set = {
          namespace        = "arc-shared"
          create_namespace = true
          min_runners      = 2
          max_runners      = 4
        }
      }
      "prod-runners-blue" = {
        visibility = "all"
        scale_set = {
          namespace        = "arc-shared"
          create_namespace = true
          min_runners      = 1
          max_runners      = 3
        }
      }
    }

    actions_runner_controller = {
      name             = "arc-controller"
      namespace        = "arc-system"
      create_namespace = true
      version          = "0.13.0"
      github_token     = "ghp_test123456789"
    }

    settings = {
      billing_email = "test@example.com"
    }
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_set_count == 2
    error_message = "Should create two scale sets"
  }

  assert {
    condition     = length(module.actions_runner_scale_set[0].namespace_names) == 1
    error_message = "Shared namespace should be created only once"
  }

  assert {
    condition     = length(distinct(values(module.actions_runner_scale_set[0].github_secret_names))) == 1
    error_message = "GitHub credentials secret should be reused across scale sets in the same namespace"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["prod-runners"].namespace == "arc-shared"
    error_message = "prod-runners scale set should target arc-shared namespace"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["prod-runners-blue"].namespace == "arc-shared"
    error_message = "prod-runners-blue scale set should target arc-shared namespace"
  }
}

run "test_scale_set_defaults" {
  command = plan

  variables {
    mode         = "organization"
    name         = "test-org"
    github_org   = "test-org"
    repositories = {}

    runner_groups = {
      "default-runners" = {
        scale_set = {} # Use all defaults
      }
    }

    actions_runner_controller = {
      github_token = "ghp_test123456789"
    }

    settings = {
      billing_email = "test@example.com"
    }
  }

  # Should create scale set module with defaults
  assert {
    condition     = length(module.actions_runner_scale_set) == 1
    error_message = "Scale set module should be created"
  }

  # Verify default values are applied
  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["default-runners"].min_runners == 1
    error_message = "Should use default min_runners = 1"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["default-runners"].max_runners == 5
    error_message = "Should use default max_runners = 5"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["default-runners"].runner_image == "ghcr.io/actions/actions-runner:latest"
    error_message = "Should use default runner image"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["default-runners"].container_mode == "dind"
    error_message = "Should use default container_mode = dind"
  }

  assert {
    condition     = module.actions_runner_scale_set[0].scale_sets["default-runners"].namespace == "arc-runners"
    error_message = "Should use default namespace = arc-runners"
  }

  # Verify no private registry
  assert {
    condition     = module.actions_runner_scale_set[0].has_private_registry == false
    error_message = "Should not have private registry configured"
  }

  # Should create runner group with defaults
  assert {
    condition     = contains(keys(github_actions_runner_group.this), "default-runners")
    error_message = "Should create default-runners group"
  }

  # Runner group should have "all" visibility by default
  assert {
    condition     = github_actions_runner_group.this["default-runners"].visibility == "all"
    error_message = "Should use 'all' visibility by default"
  }
}
