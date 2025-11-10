terraform {
  required_version = ">= 1.0"
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

locals {
  controller_repository        = "oci://ghcr.io/actions/actions-runner-controller-charts"
  controller_chart             = "gha-runner-scale-set-controller"
  scale_set_repository         = "oci://ghcr.io/actions/actions-runner-controller-charts"
  scale_set_chart              = "gha-runner-scale-set"
  github_creds_secret_name     = "arc-github-creds"
  private_registry_secret_name = "arc-private-registry-creds"

  # Create a map of scale sets that need namespace creation
  # We do this in a local to avoid using sensitive values in for_each
  scale_sets_with_namespace = { for k, v in var.scale_sets : k => v if v.create_namespace == true }

  github_repositories = var.github_repositories != null ? var.github_repositories : try(data.github_repositories.all[0], null)
  repository_id = { for r in try(local.github_repositories.names, []) :
    r => element(local.github_repositories.repo_ids, index(local.github_repositories.names, r))
  }
}

data "github_repositories" "all" {
  count           = var.github_repositories == null && var.scale_sets != null && anytrue([for ss in values(var.scale_sets) : ss.visibility == "selected"]) ? 1 : 0
  query           = "org:${var.github_org}"
  include_repo_id = true
}

resource "github_actions_runner_group" "this" {
  for_each   = { for k, v in var.scale_sets : k => v if v.create_runner_group == true }
  name       = coalesce(each.value.runner_group, each.key)
  visibility = each.value.visibility == "selected" ? "selected" : "all"
  selected_repository_ids = each.value.visibility == "selected" ? [for r in each.value.repositories :
    try(local.repository_id[r], r)
  ] : null
  restricted_to_workflows    = try(length(each.value.workflows), 0) != 0
  selected_workflows         = try(each.value.workflows, null)
  allows_public_repositories = each.value.visibility != "private" ? true : false
}

resource "kubernetes_namespace" "controller" {
  count = var.controller.create_namespace ? 1 : 0

  metadata {
    name = var.controller.namespace
  }
}

resource "helm_release" "controller" {
  count      = var.controller != null ? 1 : 0
  name       = var.controller.name
  repository = local.controller_repository
  chart      = local.controller_chart
  version    = var.controller.version
  namespace  = var.controller.namespace
  depends_on = [kubernetes_namespace.controller]
}


resource "kubernetes_namespace" "scale_set" {
  for_each = { for k, v in var.scale_sets : k => v if v.create_namespace == true }

  metadata {
    name = each.value.namespace
  }
}

resource "kubernetes_secret" "github_creds" {
  for_each = { for k, v in var.scale_sets : k => v if v.create_namespace == true }
  metadata {
    name      = local.github_creds_secret_name
    namespace = kubernetes_namespace.scale_set[each.key].metadata[0].name
  }
  data = var.github_token != null ? {
    github_token = tostring(var.github_token)
    } : {
    github_app_id              = tostring(var.github_app_id)
    github_app_installation_id = tostring(var.github_app_installation_id)
    github_app_private_key     = var.github_app_private_key
  }
}

resource "kubernetes_secret" "private_registry_creds" {
  # Create secret for each scale set that creates a namespace
  for_each = local.scale_sets_with_namespace

  metadata {
    name      = local.private_registry_secret_name
    namespace = kubernetes_namespace.scale_set[each.key].metadata[0].name
  }

  # Provide dummy data if no private registry is configured
  # The secret will exist but won't be used by helm if not referenced
  data = var.private_registry != null ? {
    ".dockerconfigjson" = jsonencode({
      auths = {
        format("%s", var.private_registry) = {
          username = var.private_registry_username
          password = var.private_registry_password
          email    = "arc-private-registry-creds@${each.key}.local"
          auth     = base64encode("${var.private_registry_username}:${var.private_registry_password}")
        }
      }
    })
    } : {
    ".dockerconfigjson" = jsonencode({
      auths = {}
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}


resource "helm_release" "scale_set" {
  for_each   = var.scale_sets
  name       = each.key
  repository = local.scale_set_repository
  chart      = local.scale_set_chart
  version    = each.value.version
  namespace  = each.value.namespace
  set = concat([
    {
      name  = "runnerGroup"
      value = coalesce(each.value.runner_group, each.key)
    },
    {
      name  = "githubConfigUrl"
      value = format("https://github.com/%s", lower(var.github_org))
    },
    {
      name  = "githubConfigSecret"
      value = local.github_creds_secret_name
    },
    {
      name  = "minRunners"
      value = tostring(each.value.min_runners)
    },
    {
      name  = "maxRunners"
      value = tostring(each.value.max_runners)
    },
    {
      name  = "template.spec.containers[0].name"
      value = "runner"
    },
    {
      name  = "template.spec.containers[0].command[0]"
      value = "/home/runner/run.sh"
    },
    {
      name  = "template.spec.containers[0].imagePullPolicy"
      value = each.value.pull_always ? "Always" : "IfNotPresent"
    },
    {
      name  = "template.spec.containers[0].image"
      value = each.value.runner_image
    }],
    var.private_registry != null ? [
      {
        name  = "template.spec.imagePullSecrets[0].name"
        value = local.private_registry_secret_name
      }
    ] : [],
    each.value.container_mode == null ? [] : [
      {
        name  = "containerMode.type"
        value = each.value.container_mode
      }
    ]
  )
  depends_on = [
    helm_release.controller,
    kubernetes_secret.github_creds,
    kubernetes_secret.private_registry_creds
  ]
}
