terraform {
  required_version = ">= 1"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "github" {
  owner = var.github_org
  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = var.github_app_private_key
  }
}

provider "kubernetes" {
  config_path    = var.kubernetes_config_path
  config_context = var.kubernetes_config_context
}

provider "helm" {
  kubernetes = {
    config_path    = var.kubernetes_config_path
    config_context = var.kubernetes_config_context
  }
}

# Fetch all repositories in the organization. If not provided, this will be fetched by the module.
data "github_repositories" "all" {
  query           = "org:${var.github_org}"
  include_repo_id = true
}

module "arc" {
  source                     = "../../"
  github_org                 = var.github_org
  github_app_id              = var.github_app_id
  github_app_private_key     = var.github_app_private_key
  github_app_installation_id = var.github_app_installation_id
  github_repositories        = data.github_repositories.all
  private_registry           = var.private_registry
  private_registry_username  = var.private_registry_username
  private_registry_password  = var.private_registry_password

  scale_sets = {
    "self-hosted" = {
      namespace   = "github-runners"
      max_runners = 4
      min_runners = 2
    }
    "dependabot" = {
      namespace    = "github-dependabot-runners"
      max_runners  = 2
      min_runners  = 1
      runner_image = "docker.prisamedia.com/prisamedia/devops-platform/actions-runner:0.4.0"
      pull_always  = false
    }
    "only-simple-2" = {
      namespace        = "github-runners"
      create_namespace = false
      max_runners      = 2
      min_runners      = 1
      visibility       = "selected"
      repositories     = ["simple-2"]
    }
    "only-simple-2b" = {
      namespace           = "github-runners"
      create_namespace    = false
      runner_group        = "only-simple-2"
      create_runner_group = false
      max_runners         = 2
      min_runners         = 1
    }
  }
}
