# Terraform Native Tests for GitHub Actions Runner Scale Set module

# Mock providers to avoid real connections during tests
mock_provider "github" {
  alias = "mock_github"
}

mock_provider "kubernetes" {
  alias = "mock_kubernetes"
}

mock_provider "helm" {
  alias = "mock_helm"
}

# Test 1: Validate that the controller is created correctly
run "validate_controller_creation" {
  command = plan

  providers = {
    github     = github.mock_github
    kubernetes = kubernetes.mock_kubernetes
    helm       = helm.mock_helm
  }

  variables {
    github_org   = "test-org"
    github_token = "test-token"
    controller = {
      name             = "arc-controller"
      namespace        = "arc-systems"
      create_namespace = true
      version          = "0.13.0"
    }
  }

  # Verify that the controller namespace is created
  assert {
    condition     = length([for r in resource.kubernetes_namespace.controller : r]) == 1
    error_message = "Exactly one namespace must be created for the controller"
  }

  # Verify that the controller helm release is created
  assert {
    condition     = length([for r in resource.helm_release.controller : r]) == 1
    error_message = "Exactly one helm release must be created for the controller"
  }

  # Verify the controller namespace
  assert {
    condition     = resource.kubernetes_namespace.controller[0].metadata[0].name == "arc-systems"
    error_message = "The controller namespace must be 'arc-systems'"
  }
}

# Test 2: Validate that scale sets are created with default configuration
run "validate_default_scale_set" {
  command = plan

  providers = {
    github     = github.mock_github
    kubernetes = kubernetes.mock_kubernetes
    helm       = helm.mock_helm
  }

  variables {
    github_org   = "test-org"
    github_token = "test-token"
  }

  # Verify that at least one scale set is created
  assert {
    condition     = length(keys(resource.helm_release.scale_set)) >= 1
    error_message = "At least one scale set must be created by default"
  }

  # Verify that the scale set namespace is created
  assert {
    condition     = length(keys(resource.kubernetes_namespace.scale_set)) >= 1
    error_message = "At least one namespace must be created for the scale set"
  }

  # Verify that the GitHub secret is created
  assert {
    condition     = length(keys(resource.kubernetes_secret.github_creds)) >= 1
    error_message = "At least one secret must be created for GitHub credentials"
  }
}

# Test 3: Validate multiple scale sets
run "validate_multiple_scale_sets" {
  command = plan

  providers = {
    github     = github.mock_github
    kubernetes = kubernetes.mock_kubernetes
    helm       = helm.mock_helm
  }

  variables {
    github_org   = "test-org"
    github_token = "test-token"
    scale_sets = {
      "runner-set-1" = {
        namespace   = "runners-1"
        min_runners = 2
        max_runners = 10
        visibility  = "all"
      }
      "runner-set-2" = {
        namespace   = "runners-2"
        min_runners = 1
        max_runners = 5
        visibility  = "private"
      }
    }
  }

  # Verify that two scale sets are created
  assert {
    condition     = length(keys(resource.helm_release.scale_set)) == 2
    error_message = "Exactly 2 scale sets must be created"
  }

  # Verify that two namespaces are created
  assert {
    condition     = length(keys(resource.kubernetes_namespace.scale_set)) == 2
    error_message = "Exactly 2 namespaces must be created"
  }

  # Verify that two secrets are created
  assert {
    condition     = length(keys(resource.kubernetes_secret.github_creds)) == 2
    error_message = "Exactly 2 secrets must be created"
  }
}

# Test 4: Validate GitHub App usage instead of token
run "validate_github_app_auth" {
  command = plan

  providers = {
    github     = github.mock_github
    kubernetes = kubernetes.mock_kubernetes
    helm       = helm.mock_helm
  }

  variables {
    github_org                 = "test-org"
    github_app_id              = 123456
    github_app_installation_id = 789012
    github_app_private_key     = "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----"
  }

  # Verify that the secret with GitHub App credentials is created
  assert {
    condition     = length(keys(resource.kubernetes_secret.github_creds)) >= 1
    error_message = "At least one secret must be created for GitHub App credentials"
  }
}

# Test 5: Validate private registry configuration
run "validate_private_registry" {
  command = plan

  providers = {
    github     = github.mock_github
    kubernetes = kubernetes.mock_kubernetes
    helm       = helm.mock_helm
  }

  variables {
    github_org                = "test-org"
    github_token              = "test-token"
    private_registry          = "registry.example.com"
    private_registry_username = "registry-user"
    private_registry_password = "registry-pass"
  }

  # Verify that the secret for the private registry is created
  assert {
    condition     = length(keys(resource.kubernetes_secret.private_registry_creds)) >= 1
    error_message = "At least one secret must be created for the private registry"
  }

  # Verify that the secret has the correct type
  assert {
    condition     = alltrue([for s in resource.kubernetes_secret.private_registry_creds : s.type == "kubernetes.io/dockerconfigjson"])
    error_message = "The private registry secret must be of type kubernetes.io/dockerconfigjson"
  }
}

# Test 6: Validate that runner groups are created correctly
run "validate_runner_groups" {
  command = plan

  providers = {
    github     = github.mock_github
    kubernetes = kubernetes.mock_kubernetes
    helm       = helm.mock_helm
  }

  variables {
    github_org   = "test-org"
    github_token = "test-token"
    scale_sets = {
      "runner-set-with-group" = {
        runner_group        = "custom-group"
        create_runner_group = true
        visibility          = "all"
      }
    }
  }

  # Verify that the runner group is created
  assert {
    condition     = length(keys(resource.github_actions_runner_group.this)) >= 1
    error_message = "At least one runner group must be created"
  }
}

# Test 7: Validate variable validations
run "validate_version_format" {
  command = plan

  providers = {
    github     = github.mock_github
    kubernetes = kubernetes.mock_kubernetes
    helm       = helm.mock_helm
  }

  variables {
    github_org   = "test-org"
    github_token = "test-token"
    controller = {
      version = "0.13.0"
    }
    scale_sets = {
      "test-runner" = {
        version = "0.13.0"
      }
    }
  }

  # Verify that valid versions are accepted
  assert {
    condition     = length(keys(resource.helm_release.scale_set)) >= 1
    error_message = "Valid versions must be accepted"
  }
}

# Test 8: Validate container mode configuration
run "validate_container_modes" {
  command = plan

  providers = {
    github     = github.mock_github
    kubernetes = kubernetes.mock_kubernetes
    helm       = helm.mock_helm
  }

  variables {
    github_org   = "test-org"
    github_token = "test-token"
    scale_sets = {
      "runner-dind" = {
        container_mode = "dind"
      }
      "runner-kubernetes" = {
        container_mode = "kubernetes"
      }
    }
  }

  # Verify that both scale sets are created
  assert {
    condition     = length(keys(resource.helm_release.scale_set)) == 2
    error_message = "Scale sets with different container modes must be created"
  }
}

# Test 9: Validate dependencies between resources
run "validate_dependencies" {
  command = plan

  providers = {
    github     = github.mock_github
    kubernetes = kubernetes.mock_kubernetes
    helm       = helm.mock_helm
  }

  variables {
    github_org   = "test-org"
    github_token = "test-token"
  }

  # Verify that the controller exists (required by scale sets)
  assert {
    condition     = length([for r in resource.helm_release.controller : r]) == 1
    error_message = "The controller must exist before creating scale sets"
  }

  # Verify that the secrets exist (required by scale sets)
  assert {
    condition     = length(keys(resource.kubernetes_secret.github_creds)) >= 1
    error_message = "Secrets must exist before creating scale sets"
  }
}

# Test 10: Validate module outputs
run "validate_module_outputs" {
  command = plan

  providers = {
    github     = github.mock_github
    kubernetes = kubernetes.mock_kubernetes
    helm       = helm.mock_helm
  }

  variables {
    github_org   = "test-org"
    github_token = "test-token"
  }

  # Verify that the controller output exists
  assert {
    condition     = output.controller != null
    error_message = "The 'controller' output must be defined"
  }

  # Verify that the scale_set output exists
  assert {
    condition     = output.scale_sets != null
    error_message = "The 'scale_sets' output must be defined"
  }
}
