# GitHub Repository Governance Module

[![Release](https://img.shields.io/github/v/release/vmvarela/terraform-github-governance?logo=github)](https://github.com/vmvarela/terraform-github-governance/releases)
[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.7-623CE4?logo=terraform)](https://www.terraform.io)

Manage GitHub repositories at scale from a single `tfvars` file. Define named presets once, apply them across repositories, and override individual fields per repo. The module handles branch protection rulesets, permissions, environments, secrets, webhooks, and naming conventions.

For single-repository management, use the [`modules/repository`](./modules/repository/) submodule directly.

## Quick Start

```hcl
module "governance" {
  source = "path/to/module"

  organization      = "my-org"
  repository_naming = "myorg-%s"  # Creates: myorg-api-service, myorg-worker, etc.

  presets = {
    service = {
      protected_branches = ["main"]
      required_approvals = 2
      required_checks    = ["ci", "security-scan"]
      allow_bypass       = ["org-admin"]
    }
  }

  repositories = {
    api-service = {
      preset      = "service"
      description = "Main API"
      topics      = ["api", "backend"]
    }
    worker = {
      preset      = "service"
      description = "Background worker"
    }
  }
}
```

## Presets

Presets are named bundles of defaults. Every field is optional — unset fields fall back to the module's built-in defaults (private visibility, `main` branch, 1 approval required, force push blocked).

```hcl
presets = {
  default = {}  # always present; override base defaults here

  production = {
    protected_branches      = ["main", "release/*"]
    required_approvals      = 2
    required_checks         = ["ci", "security-scan"]
    allow_bypass            = ["org-admin", "team:sre"]
    delete_branch_on_merge  = true
  }

  library = {
    visibility         = "public"
    protected_branches = ["main"]
    required_checks    = ["test", "lint"]
    has_wiki           = false
  }
}
```

A repository inherits its preset, then applies per-repo overrides on top:

```hcl
repositories = {
  critical-api = {
    preset             = "production"
    required_approvals = 3             # override: bump from 2 to 3
    topics             = ["critical"]
  }
}
```

## Repository Options

### Renaming without recreation

The map key is Terraform's stable identifier. Add a `name` field to change the GitHub name without destroying the resource:

```hcl
repositories = {
  auth-service = {            # key never changes
    name   = "auth-svc-v2"   # GitHub name can change freely
    preset = "production"
  }
}
```

### Environments

Environments with optional required reviewers, secrets, and variables:

```hcl
environments = {
  production = {
    required_approvers = ["team:sre", "user:alice"]
    secrets            = { API_KEY = "prod-value" }
    variables          = { ENV = "production" }
  }
  staging = {
    variables = { ENV = "staging" }
  }
}
```

Reviewers must have at least `push` permission. The module auto-elevates any reviewer who doesn't — set a higher role explicitly in `permissions` if needed.

### Permissions and bypass actors

```hcl
permissions = {
  "team:engineers" = "push"
  "team:external"  = "pull"
  "user:alice"     = "admin"
}

allow_bypass = ["org-admin", "role:maintain", "team:sre", "app:renovate"]
```

Valid bypass formats: `org-admin` · `role:maintain|write|admin` · `team:<slug>` · `app:<slug>`

### Custom properties and workspace

```hcl
workspace = "platform"   # stored as a custom property on every repo

repositories = {
  api = {
    properties = {
      cost_center = "engineering"
      tier        = "production"
    }
  }
}
```

## Testing

```bash
terraform test           # all tests (governance + submodule)
terraform test -filter=tests/governance.tftest.hcl
```

27 tests cover: preset application and overrides, naming patterns, renaming, merge strategies, feature toggles, security settings, environments, workspace injection.

## Examples

- [`examples/simple/`](./examples/simple/) — basic preset usage
- [`examples/complete/`](./examples/complete/) — overrides, renaming, templates, environments

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 6.8.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | 6.11.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_repositories"></a> [repositories](#module\_repositories) | ./modules/repository | n/a |

## Resources

| Name | Type |
|------|------|
| [github_app.bypass_apps](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/app) | data source |
| [github_organization_repository_roles.all](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/organization_repository_roles) | data source |
| [github_organization_teams.all](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/organization_teams) | data source |
| [github_user.referenced_users](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/user) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_github_app_ids"></a> [github\_app\_ids](#input\_github\_app\_ids) | Optional map of app slug -> app installation ID. If empty, fetches apps individually via data source. Used for branch protection bypass actors. | `map(number)` | `{}` | no |
| <a name="input_github_team_ids"></a> [github\_team\_ids](#input\_github\_team\_ids) | Optional map of team slug -> team ID. If empty, fetches all organization teams via data source. Used for branch protection bypass actors and environment reviewers. | `map(number)` | `{}` | no |
| <a name="input_github_user_ids"></a> [github\_user\_ids](#input\_github\_user\_ids) | Optional map of user login -> numeric user ID. If empty, repository module resolves IDs individually via data source (less efficient). Used for environment reviewers. Cannot be auto-fetched org-wide as GitHub API returns node IDs (strings) not numeric IDs. | `map(number)` | `{}` | no |
| <a name="input_organization"></a> [organization](#input\_organization) | GitHub organization name where repositories will be created. | `string` | n/a | yes |
| <a name="input_presets"></a> [presets](#input\_presets) | Preset configurations map. Select with repositories[*].preset; falls back to 'default'. | <pre>map(object({<br/>    description             = optional(string)<br/>    visibility              = optional(string)<br/>    default_branch          = optional(string)<br/>    topics                  = optional(list(string), [])<br/>    properties              = optional(map(string), {})<br/>    protected_branches      = optional(list(string))<br/>    allow_bypass            = optional(list(string), [])<br/>    required_approvals      = optional(number)<br/>    required_checks         = optional(list(string))<br/>    prevent_force_push      = optional(bool)<br/>    prevent_branch_deletion = optional(bool)<br/><br/>    # Merge settings<br/>    allow_merge_commit          = optional(bool)<br/>    allow_squash_merge          = optional(bool)<br/>    allow_rebase_merge          = optional(bool)<br/>    allow_auto_merge            = optional(bool)<br/>    delete_branch_on_merge      = optional(bool)<br/>    allow_update_branch         = optional(bool)<br/>    squash_merge_commit_title   = optional(string)<br/>    squash_merge_commit_message = optional(string)<br/>    merge_commit_title          = optional(string)<br/>    merge_commit_message        = optional(string)<br/><br/>    # Feature toggles<br/>    has_issues      = optional(bool)<br/>    has_wiki        = optional(bool)<br/>    has_projects    = optional(bool)<br/>    has_discussions = optional(bool)<br/><br/>    # Security<br/>    vulnerability_alerts        = optional(bool)<br/>    web_commit_signoff_required = optional(bool)<br/>  }))</pre> | <pre>{<br/>  "default": {}<br/>}</pre> | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Map of repositories to create. The map key is a stable identifier (won't trigger recreation). Use 'name' field to rename repositories safely. | <pre>map(object({<br/>    # Optional preset to apply (defaults to "default")<br/>    preset = optional(string, "default")<br/><br/>    # Optional explicit name (allows renaming without Terraform recreation)<br/>    name = optional(string)<br/><br/>    # Core configuration (can override preset)<br/>    description    = optional(string)<br/>    visibility     = optional(string)<br/>    default_branch = optional(string)<br/>    topics         = optional(list(string))<br/>    properties     = optional(map(string))<br/><br/>    # Template<br/>    is_template = optional(bool)<br/>    template = optional(object({<br/>      repository           = string<br/>      include_all_branches = optional(bool, false)<br/>    }))<br/><br/>    # Access & Permissions<br/>    permissions = optional(map(string))<br/>    deploy_keys = optional(map(object({<br/>      key       = string<br/>      read_only = optional(bool, false)<br/>    })))<br/>    allowed_roles = optional(list(string))<br/><br/>    # Automation (Global)<br/>    webhooks = optional(map(object({<br/>      url    = string<br/>      events = list(string)<br/>      secret = optional(string)<br/>    })))<br/>    repository_secrets   = optional(map(string))<br/>    repository_variables = optional(map(string))<br/><br/>    # CI/CD Environments<br/>    environments = optional(map(object({<br/>      required_approvers = optional(list(string), [])<br/>      secrets            = optional(map(string))<br/>      variables          = optional(map(string))<br/>    })))<br/><br/>    # Branch Protection (flattened overrides)<br/>    protected_branches      = optional(list(string))<br/>    allow_bypass            = optional(list(string))<br/>    required_approvals      = optional(number)<br/>    required_checks         = optional(list(string))<br/>    prevent_force_push      = optional(bool)<br/>    prevent_branch_deletion = optional(bool)<br/><br/>    # Merge settings (can override preset)<br/>    allow_merge_commit          = optional(bool)<br/>    allow_squash_merge          = optional(bool)<br/>    allow_rebase_merge          = optional(bool)<br/>    allow_auto_merge            = optional(bool)<br/>    delete_branch_on_merge      = optional(bool)<br/>    allow_update_branch         = optional(bool)<br/>    squash_merge_commit_title   = optional(string)<br/>    squash_merge_commit_message = optional(string)<br/>    merge_commit_title          = optional(string)<br/>    merge_commit_message        = optional(string)<br/><br/>    # Feature toggles (can override preset)<br/>    has_issues      = optional(bool)<br/>    has_wiki        = optional(bool)<br/>    has_projects    = optional(bool)<br/>    has_discussions = optional(bool)<br/><br/>    # Repository-only settings (not in presets)<br/>    archived     = optional(bool)<br/>    homepage_url = optional(string)<br/><br/>    # Security (can override preset)<br/>    vulnerability_alerts        = optional(bool)<br/>    web_commit_signoff_required = optional(bool)<br/>  }))</pre> | `{}` | no |
| <a name="input_repository_naming"></a> [repository\_naming](#input\_repository\_naming) | sprintf-style format string for repository names. Use a single '%s' placeholder for the repository key. Example: '%s' (no prefix), 'myorg-%s' (with prefix). | `string` | `"%s"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | Optional workspace/namespace name for logical grouping of repositories. If provided, will be stored as a custom property on each repository. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_organization"></a> [organization](#output\_organization) | The GitHub organization name. |
| <a name="output_repositories"></a> [repositories](#output\_repositories) | Map of repository keys to their full output details from the repository module. |
| <a name="output_repository_names"></a> [repository\_names](#output\_repository\_names) | Map of repository keys to their GitHub names. |
| <a name="output_repository_urls"></a> [repository\_urls](#output\_repository\_urls) | Map of repository keys to their HTML URLs. |
| <a name="output_workspace"></a> [workspace](#output\_workspace) | The workspace name applied to all repositories. |
<!-- END_TF_DOCS -->
