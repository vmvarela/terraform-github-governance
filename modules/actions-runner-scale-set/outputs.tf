# Controller outputs
output "controller" {
  description = "The Helm release of the controller."
  value = var.controller != null ? {
    name      = helm_release.controller[0].name
    namespace = helm_release.controller[0].namespace
    version   = helm_release.controller[0].version
    status    = helm_release.controller[0].status
  } : null
}

output "controller_namespace" {
  description = "The namespace where the controller is deployed."
  value       = var.controller != null ? var.controller.namespace : null
}

# Scale sets outputs
output "scale_sets" {
  description = "Map of scale set names to their configuration details."
  value = { for k, v in helm_release.scale_set : k => {
    name           = v.name
    namespace      = v.namespace
    version        = v.version
    status         = v.status
    chart          = v.chart
    min_runners    = var.scale_sets[k].min_runners
    max_runners    = var.scale_sets[k].max_runners
    runner_image   = var.scale_sets[k].runner_image
    runner_group   = coalesce(var.scale_sets[k].runner_group, k)
    container_mode = var.scale_sets[k].container_mode
  } }
}

output "scale_set_names" {
  description = "List of scale set names that were created."
  value       = keys(helm_release.scale_set)
}

output "scale_set_count" {
  description = "Number of scale sets created."
  value       = length(helm_release.scale_set)
}

# Runner groups outputs
output "runner_groups" {
  description = "Map of runner group names to their details."
  value = { for k, v in github_actions_runner_group.this : k => {
    name                       = v.name
    id                         = v.id
    visibility                 = v.visibility
    allows_public_repositories = v.allows_public_repositories
    restricted_to_workflows    = v.restricted_to_workflows
    default                    = v.default
  } }
}

output "runner_group_names" {
  description = "List of runner group names that were created."
  value       = keys(github_actions_runner_group.this)
}

output "runner_group_ids" {
  description = "Map of runner group names to their IDs."
  value       = { for k, v in github_actions_runner_group.this : k => v.id }
}

# Kubernetes resources outputs
output "namespaces" {
  description = "Map of namespaces created for scale sets."
  value = {
    for scale_set, config in var.scale_sets :
    scale_set => {
      name = kubernetes_namespace.scale_set[config.namespace].metadata[0].name
      id   = kubernetes_namespace.scale_set[config.namespace].id
    }
    if contains(keys(kubernetes_namespace.scale_set), config.namespace)
  }
}

output "namespace_names" {
  description = "List of namespace names created for scale sets."
  value       = [for v in kubernetes_namespace.scale_set : v.metadata[0].name]
}

output "github_secret_names" {
  description = "Map of scale set names to their GitHub credentials secret names."
  value = {
    for scale_set, config in var.scale_sets :
    scale_set => kubernetes_secret.github_creds[config.namespace].metadata[0].name
    if contains(keys(kubernetes_secret.github_creds), config.namespace)
  }
}

output "has_private_registry" {
  description = "Whether private registry is configured."
  value       = var.private_registry != null
}

output "private_registry" {
  description = "The private registry URL if configured."
  value       = var.private_registry
}

# Summary output
output "summary" {
  description = "Summary of the scale sets deployment."
  value = {
    controller_deployed  = var.controller != null
    scale_sets_count     = length(helm_release.scale_set)
    runner_groups_count  = length(github_actions_runner_group.this)
    namespaces_count     = length(kubernetes_namespace.scale_set)
    has_private_registry = var.private_registry != null
    github_org           = var.github_org
  }
}
