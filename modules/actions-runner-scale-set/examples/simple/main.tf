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
  token = var.github_token
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

module "arc" {
  source       = "../../"
  github_org   = var.github_org
  github_token = var.github_token

  controller = {
    name      = "arc"
    namespace = "arc-systems"
  }
  scale_sets = {
    "arc-runner-set" = {
      namespace = "arc-runners"
    }
  }
}
