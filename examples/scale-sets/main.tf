terraform {
  required_version = ">= 1.6"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

provider "helm" {
  kubernetes = {
    config_path    = "~/.kube/config"
    config_context = "docker-desktop"
  }
}

module "github_governance" {
  source = "../../"

  mode = "organization"
  name = var.github_org

  # Repositories
  repositories = {
    "backend-api" = {
      description = "Production backend API"
      visibility  = "private"
      topics      = ["api", "backend", "production"]
    }
    "frontend-app" = {
      description = "Production frontend application"
      visibility  = "private"
      topics      = ["frontend", "react", "production"]
    }
    "dev-tooling" = {
      description = "Development tools and scripts"
      visibility  = "private"
      topics      = ["tools", "development"]
    }
  }

  # Runner groups with scale sets
  runner_groups = {
    "production-runners" = {
      visibility   = "selected"
      repositories = ["backend-api", "frontend-app"]

      scale_set = {
        namespace        = "arc-prod"
        create_namespace = true
        version          = "0.13.0"
        min_runners      = 2
        max_runners      = 10
        runner_image     = "ghcr.io/actions/actions-runner:2.311.0"
        pull_always      = true
        container_mode   = "dind"
      }
    }

    "development-runners" = {
      visibility   = "selected"
      repositories = ["dev-tooling"]

      scale_set = {
        namespace        = "arc-dev"
        create_namespace = true
        min_runners      = 1
        max_runners      = 5
        runner_image     = "ghcr.io/actions/actions-runner:latest"
        #container_mode   = "kubernetes" # More efficient for dev workloads
      }
    }
  }

  # Actions Runner Controller configuration
  actions_runner_controller = {
    name             = "arc-controller"
    namespace        = "arc-systems"
    create_namespace = true
    version          = "0.13.0"

    # Authentication: Choose one method
    # Option 1: GitHub Token
    github_token = var.github_token

    # Option 2: GitHub App (uncomment if using)
    # github_app_id              = var.github_app_id
    # github_app_private_key     = var.github_app_private_key
    # github_app_installation_id = var.github_app_installation_id

    # Optional: Private registry for custom runner images
    # private_registry          = var.private_registry
    # private_registry_username = var.private_registry_username
    # private_registry_password = var.private_registry_password
  }

  # Organization settings
  settings = {
    billing_email                            = var.billing_email
    description                              = "Example organization with Actions Runner Scale Sets"
    company                                  = "Example Corp"
    blog                                     = "https://example.com"
    email                                    = var.billing_email
    default_repository_permission            = "read"
    members_can_create_repositories          = false
    members_can_create_public_repositories   = false
    members_can_create_private_repositories  = false
    members_can_create_internal_repositories = false
    members_can_fork_private_repositories    = false
    # web_commit_signoff_required                                  = true
    advanced_security_enabled_for_new_repositories               = true
    dependabot_alerts_enabled_for_new_repositories               = true
    dependabot_security_updates_enabled_for_new_repositories     = true
    dependency_graph_enabled_for_new_repositories                = true
    secret_scanning_enabled_for_new_repositories                 = true
    secret_scanning_push_protection_enabled_for_new_repositories = true
  }
}
