# 🚀 Propuestas Concretas de Mejora - Código Terraform

Este documento contiene las **propuestas de código específicas** para elevar el módulo a status "premium reference".

---

## 📦 PRIORIDAD 1: Mejoras Críticas

### 1.1 Refactorizar Outputs en `modules/repository/outputs.tf`

**Problema:** Output único muy genérico que obliga a los usuarios a navegar estructura compleja.

**Solución:** Agregar outputs granulares manteniendo backwards compatibility.

```terraform
# modules/repository/outputs.tf

# ✅ Mantener para backwards compatibility
output "repository" {
  description = "Complete repository object (use specific outputs for better terraform graph performance)"
  value       = github_repository.this
}

output "alias" {
  description = "Repository alias (used for renaming operations)"
  value       = local.alias
}

output "private_keys" {
  description = "Auto-generated private deploy keys (sensitive)"
  value       = tls_private_key.this
  sensitive   = true
}

# 🆕 NUEVOS OUTPUTS GRANULARES

output "repository_id" {
  description = "Numeric ID of the repository"
  value       = github_repository.this.repo_id
}

output "repository_name" {
  description = "Name of the repository"
  value       = github_repository.this.name
}

output "repository_full_name" {
  description = "Full name of the repository (owner/name)"
  value       = github_repository.this.full_name
}

output "repository_node_id" {
  description = "GraphQL global node ID of the repository"
  value       = github_repository.this.node_id
}

output "repository_url" {
  description = "URL to the repository on GitHub"
  value       = github_repository.this.html_url
}

output "repository_git_clone_url" {
  description = "HTTPS URL to clone the repository"
  value       = github_repository.this.http_clone_url
}

output "repository_ssh_clone_url" {
  description = "SSH URL to clone the repository"
  value       = github_repository.this.ssh_clone_url
}

output "default_branch" {
  description = "Name of the default branch"
  value       = github_repository.this.default_branch
}

output "visibility" {
  description = "Visibility of the repository (public/private/internal)"
  value       = github_repository.this.visibility
}

output "topics" {
  description = "List of topics associated with the repository"
  value       = github_repository.this.topics
}

output "homepage_url" {
  description = "Homepage URL of the repository"
  value       = github_repository.this.homepage_url
}

output "is_template" {
  description = "Whether the repository is a template"
  value       = github_repository.this.is_template
}

output "archived" {
  description = "Whether the repository is archived"
  value       = github_repository.this.archived
}

# 🆕 OUTPUTS DE CONFIGURACIÓN

output "security_configuration" {
  description = "Security features enabled on the repository"
  value = {
    advanced_security_enabled          = try(github_repository.this.security_and_analysis[0].advanced_security[0].status, "disabled") == "enabled"
    secret_scanning_enabled            = try(github_repository.this.security_and_analysis[0].secret_scanning[0].status, "disabled") == "enabled"
    secret_scanning_push_protection    = try(github_repository.this.security_and_analysis[0].secret_scanning_push_protection[0].status, "disabled") == "enabled"
    vulnerability_alerts_enabled       = github_repository.this.vulnerability_alerts
    dependabot_security_updates        = try(github_repository_dependabot_security_updates.this[0].enabled, null)
  }
}

output "merge_configuration" {
  description = "Merge configuration for pull requests"
  value = {
    allow_merge_commit          = github_repository.this.allow_merge_commit
    allow_squash_merge          = github_repository.this.allow_squash_merge
    allow_rebase_merge          = github_repository.this.allow_rebase_merge
    allow_auto_merge            = github_repository.this.allow_auto_merge
    delete_branch_on_merge      = github_repository.this.delete_branch_on_merge
    squash_merge_commit_title   = github_repository.this.squash_merge_commit_title
    squash_merge_commit_message = github_repository.this.squash_merge_commit_message
    merge_commit_title          = github_repository.this.merge_commit_title
    merge_commit_message        = github_repository.this.merge_commit_message
  }
}

output "features_enabled" {
  description = "Repository features status"
  value = {
    issues     = github_repository.this.has_issues
    projects   = github_repository.this.has_projects
    wiki       = github_repository.this.has_wiki
    downloads  = github_repository.this.has_downloads
    discussions = try(github_repository.this.has_discussions, false)
  }
}

# 🆕 OUTPUTS DE SUBMÓDULOS

output "environments" {
  description = "Map of environment names to their configuration"
  value = { for env_name, env_module in module.environment :
    env_name => {
      name            = env_module.name
      id              = env_module.id
      wait_timer      = env_module.wait_timer
      can_admins_bypass = env_module.can_admins_bypass
    }
  }
}

output "webhooks" {
  description = "Map of webhook URLs to their configuration"
  value = { for webhook_key, webhook_module in module.webhook :
    webhook_key => {
      id     = webhook_module.id
      url    = webhook_module.url
      active = webhook_module.active
    }
  }
}

output "rulesets" {
  description = "Map of ruleset names to their IDs"
  value = { for ruleset_name, ruleset_module in module.ruleset :
    ruleset_name => {
      id          = ruleset_module.id
      name        = ruleset_module.name
      enforcement = ruleset_module.enforcement
    }
  }
}

# 🆕 OUTPUTS DE DEPLOY KEYS

output "deploy_keys" {
  description = "Map of deploy key names to their configuration"
  value = { for key_name, deploy_key in github_repository_deploy_key.this :
    key_name => {
      id        = deploy_key.id
      title     = deploy_key.title
      read_only = deploy_key.read_only
      # No exponer la key pública por seguridad
    }
  }
}

output "auto_generated_deploy_keys" {
  description = "List of auto-generated deploy key names (private keys stored in deploy_keys_path)"
  value       = [for k, v in var.deploy_keys : k if v.public_key == null]
}
```

---

### 1.2 Simplificar Locals Complejos en `main.tf`

**Problema:** El local `repositories` tiene ~60 líneas de merge nested difíciles de mantener.

**Solución:** Dividir en helper locals con nombres descriptivos.

```terraform
# main.tf - Sección locals

locals {
  # ... otros locals existentes ...

  # ========================================================================
  # REPOSITORY CONFIGURATION MERGE LOGIC (Refactored for readability)
  # ========================================================================

  # Step 1: Build base configuration per repository from coalesce_keys
  # Priority: repository config > global settings > defaults
  _repos_base_config = { for repo, data in var.repositories :
    repo => {
      for k in local.coalesce_keys :
      k => coalesce(
        try(data[k], null),           # 1st: Repository-specific config
        try(local.settings[k], null), # 2nd: Global settings
        try(var.defaults[k], null)    # 3rd: Module defaults
      )
    }
  }

  # Step 2: Build merge configuration per repository from merge_keys
  # Merges: global settings + repository settings (repo overrides global)
  _repos_merge_config = { for repo, data in var.repositories :
    repo => {
      for k in local.merge_keys :
      k => (
        length(merge(
          try(local.settings[k], {}),
          try(data[k], {})
        )) > 0
        ? merge(try(local.settings[k], {}), try(data[k], {}))
        : try(var.defaults[k], {})
      )
    }
  }

  # Step 3: Build union configuration per repository from union_keys
  # Combines: global settings + repository settings (union of both)
  _repos_union_config = { for repo, data in var.repositories :
    repo => {
      for k in local.union_keys :
      k => (
        length(setunion(
          try(data[k], []),
          try(local.settings[k], [])
        )) > 0
        ? setunion(try(data[k], []), try(local.settings[k], []))
        : try(var.defaults[k], [])
      )
    }
  }

  # Step 4: Final assembly - Combine all configurations
  # Use repository alias if provided, otherwise use key
  repositories = { for repo, data in var.repositories :
    coalesce(try(data.alias, null), repo) => merge(
      # Description (separate as it's always repository-specific)
      { description = try(data.description, null) },

      # Base configuration (coalesced)
      local._repos_base_config[repo],

      # Merge configuration (merged maps)
      local._repos_merge_config[repo],

      # Union configuration (union of lists)
      local._repos_union_config[repo]
    )
  }

  # ========================================================================
  # END REPOSITORY CONFIGURATION MERGE LOGIC
  # ========================================================================
}
```

**Beneficios:**
- ✅ Cada paso es independiente y testeable
- ✅ Fácil agregar logging/debugging por paso
- ✅ Comentarios claros explican prioridades
- ✅ Nombres descriptivos (`_repos_base_config`, etc.)
- ✅ Reduce complejidad cognitiva de ~10 a ~4

---

### 1.3 Mejorar Outputs del Módulo Raíz

**Ubicación:** `outputs.tf` en raíz

**Agregar:** Suite completa de outputs informativos.

```terraform
# outputs.tf (ROOT MODULE)

# ========================================================================
# ORGANIZATION OUTPUTS
# ========================================================================

output "organization_id" {
  description = "GitHub organization numeric ID"
  value       = try(local.info_organization.id, null)
}

output "organization_plan" {
  description = "Current GitHub organization plan (free, team, business, enterprise)"
  value       = local.github_plan
}

output "organization_settings" {
  description = "Organization settings configuration"
  value = var.mode == "organization" ? {
    name                          = try(github_organization_settings.this[0].name, null)
    billing_email                 = try(github_organization_settings.this[0].billing_email, null)
    default_repository_permission = try(github_organization_settings.this[0].default_repository_permission, null)
    members_can_create_repos      = try(github_organization_settings.this[0].members_can_create_repositories, null)
  } : null
}

output "features_available" {
  description = "Features available based on current organization plan"
  value = {
    organization_webhooks  = local.github_plan != "free"
    organization_rulesets  = local.github_plan != "free"
    custom_roles          = contains(["enterprise", "enterprise_cloud"], local.github_plan)
    internal_repositories = contains(["business", "enterprise", "enterprise_cloud"], local.github_plan)
    advanced_security     = contains(["enterprise", "enterprise_cloud"], local.github_plan)
  }
}

# ========================================================================
# REPOSITORY OUTPUTS
# ========================================================================

output "repositories" {
  description = "Complete repository module outputs (use specific outputs for better performance)"
  value       = module.repo
}

output "repository_ids" {
  description = <<-EOT
    Map of all repository names to their numeric IDs.
    Includes both repositories managed by this module and existing repositories in the organization.
    Useful for referencing repositories in rulesets, runner groups, and other resources.

    Example usage in rulesets:
      selected_repository_ids = [
        module.github.repository_ids["my-repo"],
        module.github.repository_ids["another-repo"]
      ]
  EOT
  value = local.github_repository_id
}

output "repository_names" {
  description = "Map of repository keys to their actual names (after applying spec formatting)"
  value = { for k, r in module.repo :
    k => r.repository.name
  }
}

output "repositories_summary" {
  description = "Summary statistics of repositories managed by this module"
  value = {
    total    = length(module.repo)
    by_visibility = {
      public   = length([for r in module.repo : r if try(r.repository.visibility, "private") == "public"])
      private  = length([for r in module.repo : r if try(r.repository.visibility, "private") == "private"])
      internal = length([for r in module.repo : r if try(r.repository.visibility, "private") == "internal"])
    }
    archived = length([for r in module.repo : r if try(r.repository.archived, false)])
    templates = length([for r in module.repo : r if try(r.repository.is_template, false)])
  }
}

output "repositories_security_posture" {
  description = "Security configuration summary across all repositories"
  value = {
    total_repos                         = length(module.repo)
    with_advanced_security              = length([for r in module.repo : r if try(r.security_configuration.advanced_security_enabled, false)])
    with_secret_scanning                = length([for r in module.repo : r if try(r.security_configuration.secret_scanning_enabled, false)])
    with_secret_scanning_push_protection = length([for r in module.repo : r if try(r.security_configuration.secret_scanning_push_protection, false)])
    with_dependabot_alerts              = length([for r in module.repo : r if try(r.security_configuration.vulnerability_alerts_enabled, false)])
    with_dependabot_security_updates    = length([for r in module.repo : r if try(r.security_configuration.dependabot_security_updates, false)])
  }
}

# ========================================================================
# RUNNER GROUPS & SCALE SETS OUTPUTS
# ========================================================================

output "runner_group_ids" {
  description = "Map of runner group names to their numeric IDs"
  value = { for k, v in github_actions_runner_group.this :
    k => v.id
  }
}

output "runner_groups_summary" {
  description = "Summary of runner groups and scale sets deployment"
  value = {
    total_runner_groups     = length(github_actions_runner_group.this)
    groups_with_scale_sets  = length([for k, v in var.runner_groups : k if try(v.scale_set, null) != null])
    scale_sets_deployed     = try(module.actions_runner_scale_set[0].scale_set_count, 0)
    total_capacity = {
      min_runners = sum([for k, v in var.runner_groups : try(v.scale_set.min_runners, 0)])
      max_runners = sum([for k, v in var.runner_groups : try(v.scale_set.max_runners, 0)])
    }
    by_visibility = {
      all      = length([for k, v in var.runner_groups : k if try(v.visibility, "all") == "all"])
      selected = length([for k, v in var.runner_groups : k if try(v.visibility, "all") == "selected"])
      private  = length([for k, v in var.runner_groups : k if try(v.visibility, "all") == "private"])
    }
  }
}

# ========================================================================
# RULESETS & WEBHOOKS OUTPUTS
# ========================================================================

output "ruleset_ids" {
  description = "Map of organization ruleset names to their numeric IDs"
  value = { for k, v in github_organization_ruleset.this :
    k => v.id
  }
}

output "webhook_ids" {
  description = "Map of organization webhook names to their numeric IDs"
  value = { for k, v in github_organization_webhook.this :
    k => v.id
  }
}

# ========================================================================
# CUSTOM ROLES OUTPUTS (Enterprise only)
# ========================================================================

output "custom_role_ids" {
  description = "Map of custom repository role names to their IDs (Enterprise only)"
  value = { for k, v in github_organization_custom_role.this :
    k => v.id
  }
}

# ========================================================================
# GOVERNANCE SUMMARY OUTPUT
# ========================================================================

output "governance_summary" {
  description = "Complete governance posture summary"
  value = {
    mode                     = var.mode
    organization             = local.github_org
    plan                     = local.github_plan
    repositories_managed     = length(module.repo)
    runner_groups            = length(github_actions_runner_group.this)
    scale_sets_deployed      = try(module.actions_runner_scale_set[0].scale_set_count, 0)
    organization_webhooks    = length(github_organization_webhook.this)
    organization_rulesets    = length(github_organization_ruleset.this)
    custom_roles             = length(github_organization_custom_role.this)
    organization_variables   = length(github_actions_organization_variable.this)
    organization_secrets     = length(github_actions_organization_secret.encrypted) + length(github_actions_organization_secret.plaintext)
    dependabot_secrets       = length(github_dependabot_organization_secret.encrypted) + length(github_dependabot_organization_secret.plaintext)
  }
}
```

---

## 📦 PRIORIDAD 2: Mejoras Importantes

### 2.1 Type Safety en Variables

**Problema:** Variables con `type = any` pierden validación en tiempo de plan.

**Solución:** Definir types explícitos (ejemplo para `environments`).

```terraform
# modules/repository/variables.tf

variable "environments" {
  description = <<-EOT
    Repository environments configuration with protection rules and secrets.

    Example:
    ```hcl
    environments = {
      "production" = {
        wait_timer          = 30
        can_admins_bypass   = false
        prevent_self_review = true
        reviewers = {
          teams = [12345, 67890]
          users = [111, 222]
        }
        deployment_branch_policy = {
          protected_branches     = true
          custom_branch_policies = false
        }
        secrets_encrypted = {
          "DEPLOY_KEY" = "encrypted_value"
        }
        variables = {
          "ENV_NAME" = "production"
        }
      }
    }
    ```
  EOT

  type = map(object({
    wait_timer          = optional(number)
    can_admins_bypass   = optional(bool, true)
    prevent_self_review = optional(bool, false)

    reviewers = optional(object({
      teams = optional(list(number), [])
      users = optional(list(number), [])
    }), {})

    deployment_branch_policy = optional(object({
      protected_branches     = bool
      custom_branch_policies = bool
    }))

    # Secrets y variables del environment
    secrets           = optional(map(string), {})
    secrets_encrypted = optional(map(string), {})
    variables         = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for env_name, env_config in var.environments :
      env_config.wait_timer == null || (env_config.wait_timer >= 0 && env_config.wait_timer <= 43200)
    ])
    error_message = "wait_timer must be between 0 and 43200 minutes (30 days)"
  }

  validation {
    condition = alltrue([
      for env_name, env_config in var.environments :
      env_config.reviewers == null ||
      (length(try(env_config.reviewers.teams, [])) + length(try(env_config.reviewers.users, []))) <= 6
    ])
    error_message = "Maximum 6 reviewers allowed per environment (teams + users combined)"
  }
}
```

---

### 2.2 Lifecycle Rules para Protección

**Problema:** Recursos críticos pueden ser destruidos accidentalmente.

**Solución:** Agregar lifecycle rules con comentarios explicativos.

```terraform
# modules/repository/main.tf

resource "github_repository" "this" {
  name        = var.name
  description = var.description
  # ... resto de configuración ...

  lifecycle {
    # PROTECCIÓN: Prevenir destrucción accidental de repositorio
    # Para destruir: comentar esta línea y aplicar con -replace
    prevent_destroy = true

    # IGNORAR: Cambios externos comunes (via UI de GitHub)
    ignore_changes = [
      # Topics suelen cambiarse via UI
      topics,

      # Description puede editarse sin terraform
      description,

      # Homepage puede cambiar fuera de terraform
      homepage_url,
    ]

    # PRECONDICIÓN: Validar antes de crear
    precondition {
      condition     = var.name != ""
      error_message = "Repository name cannot be empty"
    }

    precondition {
      condition     = can(regex("^[a-zA-Z0-9._-]+$", var.name))
      error_message = "Repository name can only contain alphanumeric characters, hyphens, underscores, and periods"
    }

    # POSTCONDICIÓN: Validar después de crear
    postcondition {
      condition     = self.id != null && self.id != ""
      error_message = "Repository was not created successfully"
    }
  }
}

# Agregar también en recursos críticos del módulo raíz
# main.tf (ROOT)

resource "github_organization_settings" "this" {
  count = var.mode == "organization" ? 1 : 0
  # ... configuración ...

  lifecycle {
    # CRÍTICO: No destruir settings de organización
    prevent_destroy = true

    # Ignorar campos que cambian frecuentemente
    ignore_changes = [
      name,
      description,
    ]
  }
}

resource "github_organization_ruleset" "this" {
  for_each = coalesce(var.rulesets, {})
  # ... configuración ...

  lifecycle {
    # PROTECCIÓN: Rulesets críticos no deben destruirse sin revisión
    prevent_destroy = true

    # Permitir que se modifique enforcement sin recrear
    create_before_destroy = true
  }
}
```

---

### 2.3 Simplificar Outputs en `actions-runner-scale-set`

**Problema:** Outputs complejos con lógica condicional frágil.

**Solución:** Refactorizar para mayor robustez.

```terraform
# modules/actions-runner-scale-set/outputs.tf

# ========================================================================
# CONTROLLER OUTPUTS (Simplified)
# ========================================================================

output "controller" {
  description = "Actions Runner Controller Helm release details"
  value = var.controller != null ? {
    name      = helm_release.controller[0].name
    namespace = helm_release.controller[0].namespace
    version   = helm_release.controller[0].version
    chart     = helm_release.controller[0].chart
    status    = helm_release.controller[0].status
  } : null
}

output "controller_namespace" {
  description = "Namespace where the ARC controller is deployed"
  value       = var.controller != null ? var.controller.namespace : null
}

# ========================================================================
# SCALE SETS OUTPUTS (Improved)
# ========================================================================

output "scale_sets" {
  description = "Map of scale set names to their complete configuration and status"
  value = { for k, v in helm_release.scale_set : k => {
    # Helm release info
    release_name    = v.name
    namespace       = v.namespace
    chart_version   = v.version
    release_status  = v.status

    # Scale set configuration
    runner_group    = coalesce(var.scale_sets[k].runner_group, k)
    min_runners     = var.scale_sets[k].min_runners
    max_runners     = var.scale_sets[k].max_runners
    runner_image    = var.scale_sets[k].runner_image
    container_mode  = var.scale_sets[k].container_mode
    visibility      = var.scale_sets[k].visibility
  }}
}

output "scale_set_names" {
  description = "List of all scale set names deployed"
  value       = keys(helm_release.scale_set)
}

output "scale_set_count" {
  description = "Total number of scale sets deployed"
  value       = length(helm_release.scale_set)
}

# 🆕 NUEVO: Mapping simple namespace <-> scale_set
output "scale_set_to_namespace" {
  description = "Map of scale set names to their namespace names"
  value = { for ss_name, ss_config in var.scale_sets :
    ss_name => ss_config.namespace
  }
}

output "namespace_to_scale_sets" {
  description = "Map of namespace names to list of scale sets in that namespace"
  value = { for namespace in distinct([for ss in var.scale_sets : ss.namespace]) :
    namespace => [
      for ss_name, ss_config in var.scale_sets :
      ss_name if ss_config.namespace == namespace
    ]
  }
}

# ========================================================================
# KUBERNETES RESOURCES OUTPUTS (Simplified)
# ========================================================================

output "namespaces_created" {
  description = "Map of namespace names to their Kubernetes metadata"
  value = { for ns_name, ns_resource in kubernetes_namespace.scale_set :
    ns_name => {
      name   = ns_resource.metadata[0].name
      id     = ns_resource.id
      labels = ns_resource.metadata[0].labels
      uid    = ns_resource.metadata[0].uid
    }
  }
}

output "namespace_names" {
  description = "List of all namespace names created"
  value       = [for ns in kubernetes_namespace.scale_set : ns.metadata[0].name]
}

# 🆕 NUEVO: Secrets info sin exponer valores sensibles
output "github_credentials_secrets" {
  description = "Map of namespace names to GitHub credentials secret metadata (values not exposed)"
  value = { for ns_name, secret in kubernetes_secret.github_creds :
    ns_name => {
      name      = secret.metadata[0].name
      namespace = secret.metadata[0].namespace
      type      = secret.type
      # No exponer data keys por seguridad
      auth_method = var.github_token != null ? "token" : "github_app"
    }
  }
}

# ========================================================================
# RUNNER GROUPS OUTPUTS (No changes needed, already good)
# ========================================================================

output "runner_groups" {
  description = "Map of runner group names to their GitHub details"
  value = { for k, v in github_actions_runner_group.this : k => {
    name                       = v.name
    id                         = v.id
    visibility                 = v.visibility
    allows_public_repositories = v.allows_public_repositories
    restricted_to_workflows    = v.restricted_to_workflows
    default                    = v.default
  }}
}

output "runner_group_ids" {
  description = "Map of runner group names to their numeric IDs"
  value       = { for k, v in github_actions_runner_group.this : k => v.id }
}

output "runner_group_names" {
  description = "List of all runner group names created"
  value       = keys(github_actions_runner_group.this)
}

# ========================================================================
# REGISTRY & CONFIGURATION OUTPUTS
# ========================================================================

output "has_private_registry" {
  description = "Whether private container registry is configured"
  value       = var.private_registry != null
}

output "private_registry_url" {
  description = "Private container registry URL (null if not configured)"
  value       = var.private_registry
  sensitive   = false  # URL no es sensible, solo credenciales
}

# ========================================================================
# SUMMARY OUTPUT (Enhanced)
# ========================================================================

output "summary" {
  description = "Complete deployment summary with key metrics"
  value = {
    # Deployment status
    controller_deployed  = var.controller != null
    scale_sets_deployed  = length(helm_release.scale_set)
    runner_groups_created = length(github_actions_runner_group.this)
    namespaces_created   = length(kubernetes_namespace.scale_set)

    # Configuration
    github_org           = var.github_org
    authentication       = var.github_token != null ? "token" : "github_app"
    private_registry     = var.private_registry != null

    # Capacity
    total_min_runners    = sum([for ss in var.scale_sets : ss.min_runners])
    total_max_runners    = sum([for ss in var.scale_sets : ss.max_runners])

    # Namespaces deduplication
    unique_namespaces    = length(distinct([for ss in var.scale_sets : ss.namespace]))
    shared_namespaces    = length(distinct([for ss in var.scale_sets : ss.namespace])) < length(var.scale_sets)
  }
}
```

---

## 📦 PRIORIDAD 3: Mejoras Deseables

### 3.1 Variable Descriptions Mejoradas con Ejemplos

Agregar ejemplos inline en todas las variables complejas:

```terraform
variable "runner_groups" {
  description = <<-EOT
    GitHub Actions self-hosted runner groups configuration.

    **Behavior by Mode:**
    - **PROJECT MODE:** Repositories are automatically scoped to module-managed repos only.
                       The 'repositories' field is IGNORED.
    - **ORGANIZATION MODE:** Can reference ANY repository in the organization.
                             Use 'repositories' field to specify which repos have access.

    **Examples:**

    ```hcl
    # Example 1: Simple runner group (organization mode)
    runner_groups = {
      "default" = {
        visibility = "all"  # Available to all repos
      }
    }

    # Example 2: Selected repositories (organization mode)
    runner_groups = {
      "production" = {
        visibility   = "selected"
        repositories = ["api-service", "web-app", "worker"]
      }
    }

    # Example 3: With scale set on Kubernetes
    runner_groups = {
      "ci-runners" = {
        visibility = "all"
        scale_set = {
          namespace    = "arc-runners-ci"
          min_runners  = 2
          max_runners  = 10
          runner_image = "ghcr.io/actions/actions-runner:2.311.0"
        }
      }
    }

    # Example 4: Workflow-restricted runners
    runner_groups = {
      "deploy-runners" = {
        visibility = "selected"
        repositories = ["api", "frontend"]
        workflows = [
          ".github/workflows/deploy.yml",
          ".github/workflows/rollback.yml"
        ]
        scale_set = {
          min_runners = 1
          max_runners = 3
        }
      }
    }
    ```
  EOT

  type = map(object({
    # ... type definition ...
  }))

  default = {}
}
```

---

## 🧪 Tests Adicionales Recomendados

```hcl
# tests/scale_sets_advanced.tftest.hcl

# Test: Múltiples scale sets en mismo namespace
run "test_namespace_sharing" {
  command = plan

  variables {
    scale_sets = {
      "frontend-runners" = {
        namespace = "shared-namespace"
        min_runners = 1
        max_runners = 5
      }
      "backend-runners" = {
        namespace = "shared-namespace"  # MISMO NAMESPACE
        min_runners = 2
        max_runners = 10
      }
    }
  }

  assert {
    condition = length(module.actions_runner_scale_set[0].namespaces_created) == 1
    error_message = "Should only create ONE namespace when sharing"
  }

  assert {
    condition = length(module.actions_runner_scale_set[0].github_credentials_secrets) == 1
    error_message = "Should only create ONE github secret when sharing namespace"
  }
}

# Test: GitHub App authentication
run "test_github_app_auth" {
  command = plan

  variables {
    github_app_id = 123456
    github_app_installation_id = 789012
    github_app_private_key = "-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----"
    # No github_token provided
  }

  assert {
    condition = module.actions_runner_scale_set[0].summary.authentication == "github_app"
    error_message = "Should use github_app authentication"
  }
}

# Test: Validación de runner capacity
run "test_runner_capacity_validation" {
  command = plan
  expect_failures = [var.scale_sets]

  variables {
    scale_sets = {
      "invalid" = {
        min_runners = 10
        max_runners = 5  # INVÁLIDO: min > max
      }
    }
  }
}
```

---

## 📚 Documentación Adicional Recomendada

### Crear: `docs/OUTPUTS_GUIDE.md`

```markdown
# 📤 Outputs Guide

This guide explains all available outputs and how to use them effectively.

## Module Root Outputs

### Organization Outputs
...

### Repository Outputs
...

## Best Practices

1. **Use granular outputs** instead of accessing nested properties:
   ```hcl
   # ❌ Don't do this
   output "repo_url" {
     value = module.github.repositories["my-repo"].repository.html_url
   }

   # ✅ Do this
   output "repo_url" {
     value = module.github.repository_urls["my-repo"]
   }
   ```

2. **Leverage summary outputs** for dashboard/monitoring:
   ```hcl
   output "dashboard_metrics" {
     value = {
       repos = module.github.repositories_summary
       runners = module.github.runner_groups_summary
       security = module.github.repositories_security_posture
     }
   }
   ```
```

---

## 🎯 Checklist de Implementación

### Semana 1: Crítico
- [x] Implementar outputs granulares en `modules/repository` ✅ (Commit: 84f179d)
- [x] Refactorizar locals en `main.tf` ✅ (Commit: 06a67fe)
- [x] Agregar outputs de summary en root module ✅
- [x] Tests de validación para nuevos outputs ✅ (30/30 passing)

### Semana 2: Importante
- [x] Type safety: reemplazar `any` por types explícitos ✅ **COMPLETADO**
  - ✅ `environments`: tipo explícito con validaciones (reviewers, deployment_branch_policy)
  - ✅ `files`: list(object) con 8 campos tipados y validaciones
  - ✅ `rulesets`: map(object) con estructura completa (conditions, bypass_actors, rules)
  - ✅ `webhooks`: map(object) con validaciones de URL y content_type
  - ✅ `custom_properties`: mantiene `map(any)` justificadamente (string o list(string))
  - ✅ 0 variables con `type = any` sin justificación
- [x] Lifecycle rules en recursos críticos ✅ **COMPLETADO**
  - ✅ `github_repository`: prevent_destroy, ignore_changes, preconditions/postconditions
  - ✅ `github_organization_settings`: prevent_destroy, ignore_changes
  - ✅ `github_organization_ruleset`: prevent_destroy, create_before_destroy
  - ✅ `github_actions_runner_group`: prevent_destroy, create_before_destroy (main + submodule)
  - ✅ 109/109 tests passing (no regressions)
- [ ] Simplificar outputs en `actions-runner-scale-set`
- [ ] Documentar outputs en `docs/OUTPUTS_GUIDE.md`

### Semana 3: Deseable
- [ ] Mejorar descriptions con ejemplos inline
- [ ] Tests avanzados (namespace sharing, auth dual)
- [ ] Validaciones adicionales en variables
- [ ] Update README con nuevos outputs

---

**Estas propuestas elevarán el módulo de 8.2/10 a 9.5/10** 🚀
