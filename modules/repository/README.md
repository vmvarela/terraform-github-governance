# GitHub Repository Module

A flexible Terraform module for creating and managing individual GitHub repositories with comprehensive configuration options.

## Overview

This is the **repository submodule** used by the governance module. It can also be used directly for single-repository management or when you don't need preset configurations.

**For multi-repository governance with presets**, use the parent governance module instead.

## Features

- **Core Configuration**: Name, description, visibility, default branch, topics
- **Template Support**: Create repositories from templates or mark as template
- **Access Control**: Granular permissions for users and teams, deploy keys
- **Automation**: Webhooks, repository-level secrets and variables
- **CI/CD Environments**: Environment-specific protection rules, secrets, and variables
- **Branch Protection**: Flat inputs with automatic code owner review enforcement
- **Custom Properties**: Extensible metadata storage

## Usage

### Basic Repository

```hcl
module "repository" {
  source = "./modules/repository"

  name         = "my-service"
  organization = "my-org"
  workspace    = "platform"
  description  = "My service description"
  visibility   = "private"
  topics       = ["service", "backend"]
}
```

### With Branch Protection

```hcl
module "repository" {
  source = "./modules/repository"

  name         = "api-service"
  organization = "my-org"

  # Flattened branch-protection inputs
  protected_branches      = ["main", "release/*"]
  allow_bypass            = ["org-admin"]
  required_approvals      = 2
  required_checks         = ["ci", "security-scan"]
  prevent_force_push      = true
  prevent_branch_deletion = true
}
```

### With Permissions

```hcl
module "repository" {
  source = "./modules/repository"

  name         = "shared-library"
  organization = "my-org"
  visibility   = "public"

  permissions = {
    "user:john"      = "admin"
    "team:engineers" = "push"
    "team:external"  = "pull"
  }
}
```

### With Environment Protection

```hcl
module "repository" {
  source = "./modules/repository"

  name         = "web-app"
  organization = "my-org"

  environments = {
    production = {
      required_approvers = ["team:sre", "user:alice"]  # reviewers: teams and users
      secrets = {
        API_KEY = "secret-value"
      }
      variables = {
        ENV = "production"
      }
    }
  }
}
```

Omit `required_approvers` or set it to `[]` to have an environment without enforced reviewers.

## Variables

### Core Configuration

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | Yes | - | Repository name |
| `organization` | string | Yes | - | GitHub organization |
| `workspace` | string | No | `null` | Logical grouping workspace |
| `description` | string | No | `null` | Repository description |
| `visibility` | string | No | `"private"` | `public`, `private`, or `internal` |
| `default_branch` | string | No | `"main"` | Main branch name |
| `topics` | list(string) | No | `[]` | Repository topics |
| `properties` | map(string) | No | `{}` | Custom metadata |

### Template

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `is_template` | bool | No | `false` | Mark as template repository |
| `template` | object | No | `null` | Create from template |

### Access & Permissions

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `permissions` | map(string) | No | `{}` | Entity permissions (`user:name` or `team:slug` → role) |
| `deploy_keys` | map(object) | No | `{}` | SSH deploy keys |
| `allowed_roles` | list(string) | No | Built-in roles | Allowed repository roles |

### Automation

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `webhooks` | map(object) | No | `{}` | Repository webhooks |
| `repository_secrets` | map(string) | No | `{}` | Repository-level secrets |
| `repository_variables` | map(string) | No | `{}` | Repository-level variables |

### CI/CD Environments

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `environments` | map(object) | No | `{}` | Map of environment blocks each supporting `required_approvers`, `secrets`, `variables` |

### Branch Protection Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `protected_branches` | list(string) | No | `["main"]` | Branch patterns to protect |
| `allow_bypass` | list(string) | No | `[]` | Bypass actors (`org-admin`, `role:*`, `team:*`, `app:*`) |
| `required_approvals` | number | No | `1` | Required approving reviews (0 disables PR requirement) |
| `required_checks` | list(string) | No | `[]` | Required status checks contexts |
| `prevent_force_push` | bool | No | `true` | Disallow force pushes |
| `prevent_branch_deletion` | bool | No | `true` | Prevent branch deletion |

When `required_approvals > 0`, code owner review and thread resolution are enforced automatically.

### Performance Optimization

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `github_team_ids` | map(number) | No | `null` | Pre-fetched team IDs (slug → ID) used for branch bypass actors and environment approvers |
| `github_user_ids` | map(number) | No | `null` | Pre-fetched user IDs (login → ID) used for environment approvers |
| `github_app_ids` | map(number) | No | `null` | Pre-fetched app IDs (slug → installation ID) |

**Notes**:
- If these maps are not provided, the module automatically resolves referenced teams (`data.github_team`), users (`data.github_user`), and apps (`data.github_app`) as needed.
- The governance (parent) module pre-fetches org-wide teams and users and passes the maps down for optimal performance.

### Environment Reviewers & Permissions

- Minimum role: Reviewers must have at least `push` permission in the repository for GitHub to accept them as environment reviewers.
- Auto-elevation: The module automatically grants `push` to any reviewer (team/user) declared in `required_approvers` who is missing or below the minimum. To grant higher roles (e.g., `maintain`, `admin`), declare them explicitly in `permissions` — user-defined values take precedence.
- Stable ordering: Ruleset `bypass_actors` are sorted deterministically by resolved IDs to avoid plan drift due to ordering.

## Outputs

| Name | Description |
|------|-------------|
| `id` | Repository ID |
| `name` | Repository name |
| `full_name` | Full name (org/repo) |
| `html_url` | HTML URL |
| `ssh_clone_url` | SSH clone URL |
| `http_clone_url` | HTTPS clone URL |
| `node_id` | GraphQL node ID |
| `default_branch` | Default branch name |
| `protected_branches_ruleset_id` | Ruleset ID (if created) |
| `protected_branches_ruleset_created` | Whether ruleset is created (boolean) |

## Ruleset Configuration

### Branch Patterns

Use glob patterns for branches:
- `main` - Exact match
- `release/*` - All release branches
- `hotfix/*` - All hotfix branches
- `**` - All branches

### Bypass Actors

Supported formats:
- `org-admin` - Organization administrators
- `role:maintain`, `role:write`, `role:admin` - Repository roles
- `team:slug` - Team by slug
- `app:slug` - GitHub App by slug

### Example: Complex Ruleset

```hcl
ruleset = {
  branches = ["main", "release/*", "hotfix/*"]

  allow_bypass = [
    "org-admin",
    "team:sre",
    "app:renovate"
  ]

  required_approvals              = 2


  required_checks = [
    "ci",
    "security-scan",
    "integration-tests"
  ]
  prevent_force_push      = true
  prevent_branch_deletion = true
}
```

## Permissions Format

```hcl
permissions = {
  "user:alice"     = "admin"
  "user:bob"       = "push"
  "team:engineers" = "push"
  "team:external"  = "pull"
}
```

**Built-in Roles**: `pull`, `triage`, `push`, `maintain`, `admin`

**Custom Roles**: Set `allowed_roles = []` to disable validation and use custom organization roles.

## Deploy Keys

```hcl
deploy_keys = {
  "CI/CD Key" = {
    key       = "ssh-rsa AAAAB3..."
    read_only = false
  }
  "Read-only Key" = {
    key       = "ssh-rsa AAAAC4..."
    read_only = true
  }
}
```

## Webhooks

```hcl
webhooks = {
  "ci-webhook" = {
    url    = "https://ci.example.com/webhook"
    events = ["push", "pull_request"]
    secret = "webhook-secret"
  }
}
```

## Testing

The repository module includes comprehensive tests:

```bash
terraform test -filter=tests/repository.tftest.hcl
```

**Test Coverage**: 12 passing tests covering:
- ✅ Basic repository creation
- ✅ Ruleset configuration
- ✅ Permissions and access control
- ✅ Template support
- ✅ Environments
- ✅ Properties and metadata

## Important Notes

### Organization Owners and Permissions

GitHub automatically grants `admin` permission to organization owners on all repositories, regardless of the permission level specified in Terraform. This module uses `lifecycle { ignore_changes = [user] }` to prevent drift detection when organization owners are listed with lower permissions (e.g., `pull` or `push`).

**Why this happens:**
- GitHub enforces that org owners always have admin access
- Attempting to set a lower permission for an owner will be silently upgraded by GitHub
- Without `ignore_changes`, Terraform would detect this as drift on every plan

**Best practice:** Don't explicitly list organization owners in the `permissions` map unless you want to document their access. Their admin access is implicit.

## Examples

See the `examples/` directory:
- **`examples/simple/`**: Basic repository creation with minimal configuration
- **`examples/complete/`**: Advanced features (branch protection, permissions, environments)

## Requirements

- Terraform >= 1.0
- GitHub Provider = 6.8.1

## Used By

This module is used by:
- **Governance Module** (parent) - For multi-repository orchestration with presets
- **Direct Usage** - For single-repository management

## License

## Breaking Changes (Latest Refactor)

Recent simplification of environment protection:

- Removed nested `protection_rules` object; use flat `required_approvers` directly inside each environment.
- Removed `wait_timer_minutes` (grace period not supported in current implementation).
- Renamed performance optimization variables: `allow_bypass_team_ids` → `github_team_ids`, `allow_bypass_app_ids` → `github_app_ids` for consistency.
- `required_approvers` supports both team reviewers (`team:<slug>`) and user reviewers (`user:<login>`). When `github_user_ids` is not provided, the module resolves users on demand via `data.github_user`.
- Environment reviewers must have at least `push` permission; the module auto-elevates reviewers to `push` if needed.

Migration snippet:

```hcl
# Before
environments = {
  prod = {
    protection_rules = {
      required_approvers = ["team:sre"]
      wait_timer_minutes = 0
    }
  }
}

# After
environments = {
  prod = {
    required_approvers = ["team:sre"]
  }
}
```

[Your License Here]
