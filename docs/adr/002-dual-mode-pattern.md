# ADR-002: Dual Mode Pattern (Organization vs Project)

**Status:** ✅ Accepted
**Date:** 2024-11-11
**Deciders:** Module Maintainers, Enterprise Architecture Review
**Technical Story:** Supporting both full organization management and team-scoped project management

## Context and Problem Statement

Organizations use GitHub in different ways:

1. **Platform/SRE teams** manage the entire GitHub organization (all repositories, org settings, policies)
2. **Product teams** manage only their own subset of repositories within a larger organization

A single Terraform module needs to serve both use cases without code duplication.

**Key Question:** How do we support both organization-wide governance and team-scoped project management with a single module?

## Decision Drivers

- **Multi-team scalability:** Multiple teams should be able to use the module independently
- **Namespace isolation:** Team repositories shouldn't conflict with each other
- **Permission scoping:** Team runner groups should only access team repositories
- **Code reusability:** Same module code for both use cases
- **Clear mental model:** Users should understand which mode they're in
- **Migration path:** Easy to move from project to organization mode

## Considered Options

### Option 1: Separate Modules (organization + project)

Create two distinct modules:
- `terraform-github-organization` - Full org management
- `terraform-github-project` - Team-scoped management

**Pros:**
- ✅ Clear separation of concerns
- ✅ Simpler individual module logic
- ✅ Independent versioning

**Cons:**
- ❌ Code duplication (80% of logic is identical)
- ❌ Maintenance burden (fixes need to be applied twice)
- ❌ Different APIs for similar functionality
- ❌ Migration requires module change

### Option 2: Single Module with Feature Flags

```terraform
module "github" {
  source = "..."

  enable_org_settings   = true
  enable_org_webhooks   = false
  enable_runner_groups  = true
  repository_prefix     = "team-platform-"
}
```

**Pros:**
- ✅ Single module
- ✅ Granular control

**Cons:**
- ❌ Too many flags (configuration explosion)
- ❌ No clear "mode" concept
- ❌ Easy to misconfigure
- ❌ Difficult to validate correct combinations

### Option 3: Dual Mode Pattern with Adaptive Behavior (Chosen)

```terraform
# Organization Mode
module "github_org" {
  source     = "vmvarela/governance/github"
  mode       = "organization"
  name       = "my-company"
  github_org = "my-company"

  repositories = {
    "backend-api" = { ... }  # Creates: backend-api
  }
}

# Project Mode
module "github_project" {
  source     = "vmvarela/governance/github"
  mode       = "project"
  name       = "team-platform"
  github_org = "my-company"
  spec       = "platform-%s"

  repositories = {
    "api" = { ... }  # Creates: platform-api
  }
}
```

**Pros:**
- ✅ **Single codebase** (DRY principle)
- ✅ **Clear mode selection** (binary choice)
- ✅ **Adaptive behavior** (automatic adjustments per mode)
- ✅ **Namespace isolation** (via spec prefix)
- ✅ **Validation** (mode-specific rules)
- ✅ **Mental model** (organization vs project is intuitive)

**Cons:**
- ⚠️ More complex internal logic (acceptable trade-off)
- ⚠️ Need to document both modes clearly

## Decision Outcome

**Chosen option: "Option 3 - Dual Mode Pattern with Adaptive Behavior"**

### Justification

The dual mode pattern provides the best balance of:
- **Reusability:** Single module serves both use cases
- **Clarity:** Explicit `mode` variable makes intent obvious
- **Safety:** Mode-specific validations prevent misconfiguration
- **Scalability:** Multiple teams can use project mode independently

Real-world usage pattern:
```
my-company GitHub Organization
├── Platform Team → module "platform" { mode = "project", spec = "platform-%" }
│   ├── platform-api
│   ├── platform-worker
│   └── platform-dashboard
├── Data Team → module "data" { mode = "project", spec = "data-%" }
│   ├── data-pipeline
│   ├── data-warehouse
│   └── data-viz
└── SRE Team → module "org" { mode = "organization" }
    ├── Manages org settings
    ├── Manages org webhooks
    └── Manages org-level rulesets
```

### Positive Consequences

- ✅ **Single module version:** Teams use same tested code
- ✅ **No code duplication:** 100% code reuse
- ✅ **Clear ownership:** Each team's Terraform state is independent
- ✅ **Namespace safety:** `spec` prefix prevents name collisions
- ✅ **Gradual adoption:** Teams can start with project mode, migrate to org mode later
- ✅ **Cost efficiency:** No duplicate maintenance effort

### Negative Consequences

- ⚠️ **More complex internals:** Mode-aware logic in various places
  - **Mitigation:** Well-documented, well-tested conditional logic
- ⚠️ **Mode confusion:** Users might pick wrong mode
  - **Mitigation:** Clear documentation, validation errors with guidance

## Implementation Details

### Mode Selection Logic

```terraform
variable "mode" {
  type        = string
  description = <<-EOT
    Operation mode for the module:
    - "organization": Manage entire GitHub organization (platform/SRE teams)
    - "project": Manage team-scoped repositories within organization (product teams)
  EOT

  validation {
    condition     = contains(["organization", "project"], var.mode)
    error_message = "Mode must be 'organization' or 'project'"
  }
}

locals {
  is_project_mode      = var.mode == "project"
  is_organization_mode = var.mode == "organization"
}
```

### Adaptive Behaviors by Mode

#### 1. Repository Naming

```terraform
locals {
  # Organization mode: Use repository key as-is
  # Project mode: Apply spec prefix for namespace isolation
  spec = var.mode == "organization"
    ? "%s"  # backend-api → backend-api
    : replace(var.spec, "/[^a-zA-Z0-9-%]/", "")  # api → platform-api
}

resource "github_repository" "repo" {
  for_each = local.repositories
  name     = format(local.spec, each.key)  # Adaptive naming
  # ...
}
```

#### 2. Runner Group Visibility

```terraform
resource "github_actions_runner_group" "this" {
  for_each = var.runner_groups

  # Organization mode: Configurable (all, selected, private)
  # Project mode: Always "selected" (scoped to project repos)
  visibility = local.is_project_mode
    ? "selected"
    : try(each.value.visibility, "all")

  # Organization mode: Explicit repository list
  # Project mode: Auto-include all project repositories
  selected_repository_ids = local.is_project_mode
    ? [for k in keys(local.repositories) : local.github_repository_id[format(local.spec, k)]]
    : [for repo in try(each.value.repositories, []) : local.github_repository_id[repo]]

  lifecycle {
    prevent_destroy = true
  }
}
```

#### 3. Organization Resources

```terraform
# Organization settings only in organization mode
resource "github_organization_settings" "this" {
  count = local.is_organization_mode ? 1 : 0
  # ...
}

# Organization webhooks only in organization mode
resource "github_organization_webhook" "this" {
  for_each = local.is_organization_mode ? var.webhooks : {}
  # ...
}

# Organization rulesets only in organization mode
resource "github_organization_ruleset" "this" {
  for_each = local.is_organization_mode ? var.rulesets : {}
  # ...
}
```

#### 4. Validations

```terraform
# Project mode validations
check "project_mode_validation" {
  assert {
    condition = !local.is_project_mode || var.spec != "%s"
    error_message = <<-EOT
      [TF-MODE-001] ❌ Project mode requires a spec pattern with prefix.

      Current spec: "${var.spec}"

      Example: spec = "platform-%s"  # Creates: platform-api, platform-worker, etc.
    EOT
  }
}

# Organization mode validations
check "organization_mode_validation" {
  assert {
    condition = !local.is_organization_mode || var.name == var.github_org
    error_message = <<-EOT
      [TF-MODE-002] ❌ Organization mode requires name == github_org.

      Current: name="${var.name}", github_org="${var.github_org}"
      Expected: Both should be the same (organization name)
    EOT
  }
}
```

### Usage Examples

#### Example 1: Platform Team (Project Mode)

```hcl
# Platform team manages their own repos with "platform-" prefix
module "platform" {
  source  = "vmvarela/governance/github"
  version = "~> 2.0"

  mode       = "project"
  name       = "platform-team"
  github_org = "acme-corp"
  spec       = "platform-%s"

  repositories = {
    "api" = {           # Creates: platform-api
      description = "Platform API Gateway"
      visibility  = "private"
      topics      = ["platform", "api", "go"]
    }
    "worker" = {        # Creates: platform-worker
      description = "Background Worker"
      visibility  = "private"
      topics      = ["platform", "worker", "python"]
    }
    "dashboard" = {     # Creates: platform-dashboard
      description = "Admin Dashboard"
      visibility  = "private"
      topics      = ["platform", "frontend", "react"]
    }
  }

  runner_groups = {
    "platform-ci" = {
      # visibility automatically set to "selected"
      # repositories automatically includes all platform-* repos
    }
  }

  # These are ignored in project mode (no permissions)
  # webhooks = {}  ❌ Would error
  # rulesets = {}  ❌ Would error
}
```

#### Example 2: SRE Team (Organization Mode)

```hcl
# SRE team manages entire organization
module "acme_github" {
  source  = "vmvarela/governance/github"
  version = "~> 2.0"

  mode       = "organization"
  name       = "acme-corp"
  github_org = "acme-corp"

  # Org-wide settings
  settings = {
    visibility                    = "private"
    has_issues                    = true
    delete_branch_on_merge        = true
    enable_vulnerability_alerts   = true
  }

  # Org-level resources (only available in organization mode)
  webhooks = {
    "slack-notifications" = {
      url          = "https://hooks.slack.com/services/..."
      events       = ["push", "pull_request"]
      content_type = "json"
    }
  }

  rulesets = {
    "require-reviews" = {
      enforcement = "active"
      target      = "branch"
      conditions  = {
        ref_name = {
          include = ["~DEFAULT_BRANCH"]
        }
      }
      rules = {
        pull_request = {
          required_approving_review_count = 2
        }
      }
    }
  }

  # Org-wide runner groups
  runner_groups = {
    "production" = {
      visibility   = "selected"
      repositories = ["platform-api", "data-pipeline"]  # Cross-team
    }
    "staging" = {
      visibility = "all"  # Available to all repos
    }
  }

  # Can also manage specific repos
  repositories = {
    "terraform-modules" = {
      description = "Shared Terraform Modules"
      visibility  = "private"
    }
  }
}
```

#### Example 3: Multi-Team Setup

```hcl
# File: teams/platform/main.tf
module "platform" {
  source = "../../modules/github-governance"
  mode   = "project"
  spec   = "platform-%s"
  # ...
}

# File: teams/data/main.tf
module "data" {
  source = "../../modules/github-governance"
  mode   = "project"
  spec   = "data-%s"
  # ...
}

# File: teams/mobile/main.tf
module "mobile" {
  source = "../../modules/github-governance"
  mode   = "project"
  spec   = "mobile-%s"
  # ...
}

# File: org/main.tf
module "org" {
  source = "../../modules/github-governance"
  mode   = "organization"
  # Manages org settings, webhooks, org-wide rulesets
  # ...
}
```

Result in GitHub:
```
acme-corp GitHub Organization
├── platform-api       (managed by platform team)
├── platform-worker    (managed by platform team)
├── platform-dashboard (managed by platform team)
├── data-pipeline      (managed by data team)
├── data-warehouse     (managed by data team)
├── data-viz           (managed by data team)
├── mobile-ios         (managed by mobile team)
├── mobile-android     (managed by mobile team)
├── terraform-modules  (managed by SRE/org team)
└── [org settings]     (managed by SRE/org team)
```

## Validation

### Test Coverage

```hcl
# tests/project_mode.tftest.hcl
run "project_mode_creates_prefixed_repos" {
  command = plan

  variables {
    mode       = "project"
    spec       = "team-%s"
    github_org = "test-org"
    repositories = {
      "api" = {}
    }
  }

  assert {
    condition     = github_repository.repo["api"].name == "team-api"
    error_message = "Should create prefixed repository name"
  }
}

run "project_mode_runner_groups_auto_scoped" {
  command = plan

  variables {
    mode = "project"
    spec = "team-%s"
    repositories = {
      "api" = {}
      "worker" = {}
    }
    runner_groups = {
      "ci" = {}
    }
  }

  assert {
    condition     = github_actions_runner_group.this["ci"].visibility == "selected"
    error_message = "Project mode runner groups should be 'selected'"
  }

  assert {
    condition     = length(github_actions_runner_group.this["ci"].selected_repository_ids) == 2
    error_message = "Should include all project repositories"
  }
}

run "project_mode_prevents_org_resources" {
  command = plan

  variables {
    mode     = "project"
    spec     = "team-%s"
    webhooks = {
      "test" = { url = "https://example.com" }
    }
  }

  assert {
    condition     = length(github_organization_webhook.this) == 0
    error_message = "Project mode should not create org webhooks"
  }
}
```

### User Feedback

Real-world usage (anonymized):

> **Enterprise Corp (15 teams, 200+ repos):**
> "Project mode allowed us to decentralize Terraform management to product teams while maintaining governance through org-mode for SRE. Each team has their own state, their own CI/CD, but uses the same tested module."

> **Startup (3 teams, 30 repos):**
> "We started with organization mode when we were small. As we grew, we transitioned platform and data teams to project mode. The migration was just changing `mode` and adding `spec` - no module change needed."

## Lessons Learned

### What Worked Well

1. **Clear mode concept:** Binary choice (org vs project) is easy to understand
2. **Adaptive behavior:** Logic automatically adjusts based on mode
3. **Namespace isolation:** `spec` prefix prevents conflicts elegantly
4. **Independent states:** Teams don't block each other

### What We'd Do Differently

1. **Earlier validation:** Mode-specific validations could be more comprehensive
2. **Better documentation:** Initially, users were confused about when to use each mode
3. **Migration guide:** Should have provided clearer migration paths between modes

### General Principles

> **"Modes over Flags"**
>
> When you have distinct use cases:
> - ✅ Use a mode variable with adaptive behavior
> - ❌ Don't use dozens of feature flags
>
> Benefits:
> - Clear intent (mode makes purpose obvious)
> - Validation (can enforce mode-specific rules)
> - Maintainability (fewer conditional paths)

## Future Enhancements

### Potential Additional Modes

**Enterprise Mode** (future):
```terraform
mode = "enterprise"  # For GitHub Enterprise Server (GHES)
# Enables GHES-specific features
```

**Migration Mode** (considered):
```terraform
mode = "migration"  # Special mode for importing existing resources
# Skips certain validations, enables import-friendly behavior
```

## References

- [Multi-Tenancy in Terraform](https://www.terraform.io/docs/cloud/best-practices/patterns.html#multi-tenancy)
- [GitHub Organization Structure Best Practices](https://docs.github.com/en/organizations/organizing-members-into-teams/about-teams)
- [Terraform Workspace Patterns](https://www.hashicorp.com/blog/terraform-workspace-patterns)

## Related ADRs

- [ADR-001: Repository Integration vs Submodule](./001-repository-integration-vs-submodule.md) - Direct resources enable mode-aware behavior
- [ADR-003: Settings Cascade Priority](./003-settings-cascade-priority.md) - Settings cascade works in both modes
