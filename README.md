# GitHub Repository Governance Module

[![Terraform Version](https://img.shields.io/badge/terraform-%3E%3D1.0-623CE4?logo=terraform)](https://www.terraform.io)
[![GitHub Provider](https://img.shields.io/badge/provider-github%20~%3E%206.0-181717?logo=github)](https://registry.terraform.io/providers/integrations/github/latest)
[![Release](https://img.shields.io/github/v/release/vmvarela/terraform-github-governance?style=flat-square)](https://github.com/vmvarela/terraform-github-governance/releases)
[![Tests](https://img.shields.io/badge/tests-14%20passed-success?logo=terraform)](./tests/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://pre-commit.com/)

A Terraform module for managing GitHub repositories at scale with configurable presets, standardized naming patterns, and secure branch protection defaults.

## Features

- **Preset System**: Reusable configurations you define once and apply per repository
- **Standardized Naming**: Apply organization-wide naming patterns with `repository_naming`
- **Safe Renaming**: Rename repositories without Terraform resource recreation
- **Branch Protection**: Flat, intuitive configuration with automatic code owner review enforcement
- **Performance Optimization**: Central ID resolution - governance module pre-fetches all team/user/app IDs once and passes them to repository instances, eliminating duplicate API calls
- **Hierarchical Architecture**: Governance module orchestrates repository submodule for clean separation

## Module Structure

```
.
├── main.tf                          # Governance orchestration logic
├── variables.tf                     # Input variables
├── outputs.tf                       # Module outputs
├── versions.tf                      # Terraform and provider requirements
├── data.tf                          # Pre-fetch team/app IDs
├── data.tf                          # Pre-fetch team/app IDs
├── modules/
│   └── repository/                  # Repository submodule
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       ├── examples/
│       │   ├── simple/              # Basic repository usage
│       │   └── complete/            # Advanced repository features
│       └── tests/
│           └── repository.tftest.hcl
├── examples/
│   ├── simple/                      # Basic governance usage
│   └── complete/                    # Advanced governance features
└── tests/
    └── governance.tftest.hcl        # Governance module tests
```

## Quick Start

### Basic Usage

```hcl
module "governance" {
  source = "path/to/module"

  organization       = "my-org"
  workspace          = "platform"
  repository_naming  = "%s"  # No prefix, use keys as-is

  # Define any non-default presets you want to use
  presets = {
    # Example preset you can reference from repositories
    production-service = {
      protected_branches = ["main"]
      required_approvals = 2
      required_checks    = ["ci", "security-scan"]
    }
  }

  repositories = {
    api-service = {
      description = "Main API service"
      topics      = ["api", "backend"]
    }

    payment-processor = {
      preset      = "production-service" # must exist in var.presets
      description = "Payment processing service"
    }
  }
}
```

### With Name Prefix

```hcl
module "governance" {
  source = "path/to/module"

  organization = "my-org"
  workspace   = "microservices"
  repository_naming  = "myorg-%s"  # Prefix: myorg-api-service, myorg-worker, etc.

  repositories = {
    api-service = {}      # Creates "myorg-api-service"
    worker      = {}      # Creates "myorg-worker"
  }
}
```

## Defining Presets

Presets are passed via `var.presets` (only `default` exists by default). Define any number of named presets and reference them from repositories with `preset = "<name>"`.

```hcl
presets = {
  default = {
    # Optional: override base defaults (private/main, etc.)
  }

  production-service = {
    protected_branches = ["main", "release/*"]
    required_approvals = 2
    required_checks    = ["ci", "security-scan"]
    allow_bypass       = ["org-admin"]
  }

  library = {
    visibility         = "public"
    protected_branches = ["main"]
    required_checks    = ["test", "lint"]
  }
}
```

## Advanced Features

### Preset Overrides

Override specific preset values while keeping the rest:

```hcl
repositories = {
  critical-api = {
    preset                  = "production-service"  # Base: 2 approvals
    description             = "Critical API"
    protected_branches      = ["main", "release/*"]
    required_approvals      = 3  # Override: increase to 3
    required_checks         = ["ci", "security-scan", "integration-tests"]
    prevent_force_push      = true
    prevent_branch_deletion = true
    allow_bypass            = ["org-admin"]
  }
}
```

### Safe Repository Renaming

Rename repositories without Terraform resource recreation:

```hcl
repositories = {
  # Terraform key is stable (never changes)
  legacy-auth = {
    name        = "auth-service-v2"  # Actual GitHub name
    preset      = "production-service"
    description = "Authentication service (renamed)"
  }
}
```

**Renaming Process**:
1. Keep the Terraform map key stable (e.g., `legacy-auth`)
2. Add or change the `name` field to the new GitHub repository name
3. Run `terraform apply` - Terraform will rename the repository without destroying/recreating

### Custom Properties

Add custom metadata to repositories:

```hcl
repositories = {
  api = {
    description = "API service"
    properties = {
      team        = "platform"
      cost_center = "engineering"
      tier        = "production"
    }
  }
}
```

**Note**: The `workspace` property is automatically added from `workspace`.

### Template Repositories

Create template repositories and use them:

```hcl
repositories = {
  # Define a template
  service-template = {
    preset      = "library"
    is_template = true
    description = "Template for new services"
  }

  # Create from template
  new-service = {
    preset      = "staging"
    description = "New service from template"
    template = {
      repository           = "my-org/service-template"
      include_all_branches = false
    }
  }
}
```

### Environment Protection

Configure environment-specific reviewers, secrets, and variables using a flat structure:

```hcl
repositories = {
  api = {
    preset = "production-service"

    environments = {
      production = {
        required_approvers = ["team:sre", "team:security"]  # reviewers
        secrets = {
          API_KEY = "prod-secret-value"
        }
        variables = {
          ENV = "production"
        }
      }
      staging = {
        secrets = {
          API_KEY = "staging-secret-value"
        }
        variables = {
          ENV = "staging"
        }
      }
    }
  }
}
```

If `required_approvers` is omitted or an empty list, no reviewers are enforced for that environment.

#### Environment Reviewers & Permissions

- Minimum role: Reviewers (both `team:<slug>` and `user:<login>`) must have at least `push` permission on the repository for GitHub to accept them as environment reviewers.
- Auto-elevation: This module automatically grants `push` to any reviewer declared in `required_approvers` who does not already meet the minimum. If you need a higher role, set it explicitly in `permissions` and it will be respected.
- Ordering stability: Ruleset `bypass_actors` are normalized and sorted by their resolved IDs to avoid cosmetic reordering drift across plans.

## Branch Protection Ruleset
The branch-protection inputs are flat and intuitive on each repository:

```hcl
# Per-repository fields (all optional, secure defaults apply)
protected_branches      = ["main", "release/*"]
allow_bypass            = ["org-admin", "team:sre"]
required_approvals      = 2
required_checks         = ["ci", "security-scan"]
prevent_force_push      = true
prevent_branch_deletion = true
```

Ruleset behavior:
- If `required_approvals > 0`, code owner review and thread resolution are enforced automatically.
- Bypass actors can be `org-admin`, `role:<maintain|write|admin>`, `team:<slug>`, or `app:<slug>`.

## Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `organization` | string | GitHub organization name |
| `workspace` | string | workspace/namespace for logical grouping |

### Optional

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `repository_naming` | string | `"%s"` | sprintf-style format string for repository names |
| `repositories` | map(object) | `{}` | Map of repositories to create |
| `presets` | map(object) | `{ default = {} }` | Named presets you define and reference |

### Repository Object

```hcl
{
  preset             = optional(string, "default")
  name               = optional(string)           # For renaming
  description        = optional(string)
  visibility         = optional(string)           # "public", "private", "internal"
  default_branch     = optional(string)
  topics             = optional(list(string))
  properties         = optional(map(string))
  is_template        = optional(bool)
  template           = optional(object)
  permissions        = optional(map(string))
  deploy_keys        = optional(map(object))
  allowed_roles      = optional(list(string))
  webhooks           = optional(map(object))
  repository_secrets = optional(map(string))    # or map(object({ value = string, sensitive = optional(bool, true) }))
  repository_variables = optional(map(string))
  environments       = optional(map(object))

  # Branch protection (flattened)
  protected_branches      = optional(list(string))
  allow_bypass            = optional(list(string))
  required_approvals      = optional(number)
  required_checks         = optional(list(string))
  prevent_force_push      = optional(bool)
  prevent_branch_deletion = optional(bool)
}
```

## Outputs

| Name | Description |
|------|-------------|
| `repositories` | Map of repositories with id, names, URLs, default_branch, and `protected_branches_ruleset_id` |
| `repository_names` | Map of keys to GitHub names |
| `repository_urls` | Map of keys to HTML URLs |
| `workspace` | The workspace applied to all repositories |
| `organization` | The GitHub organization name |

Note: Each submodule instance also exposes `protected_branches_ruleset_created` (boolean) for plan-phase assertions.

## Testing

Run tests with:

```bash
terraform test
```

**Test Coverage**:
- ✅ Preset application (default, production-service, library, staging, experimental, documentation)
- ✅ Name format with and without prefix
- ✅ Explicit name field for renaming
- ✅ Preset overrides (approvals, visibility, checks)
- ✅ workspace injection into properties
- ✅ Multiple repositories with different presets
- ✅ Topics and properties merging

## Examples

See the `examples/` directory:
- **`examples/simple/`**: Basic governance with preset usage
- **`examples/complete/`**: Advanced governance features (overrides, renaming, templates, environments)

For repository submodule examples:
- **`modules/repository/examples/simple/`**: Basic repository usage
- **`modules/repository/examples/complete/`**: Advanced repository features

## Requirements

- Terraform >= 1.0
- GitHub Provider = 6.8.2

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.


---

## Acknowledgments

- Built with [Terraform](https://www.terraform.io/) and the [GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest)
- Uses [terraform-docs](https://terraform-docs.io/) for documentation generation
- Testing with native [Terraform Test](https://developer.hashicorp.com/terraform/language/tests)

---

**Made with ❤️ by [Victor Varela](https://github.com/vmvarela)**

## Secrets

**Do not commit secrets**: Never commit tokens or secret values in the repository or in `terraform.tfvars`. Use GitHub Actions secrets, environment variables, or a secret manager (OIDC). Example: set `GITHUB_TOKEN` in your CI environment and reference it via `var.github_token`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | 6.10.2 |

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
| <a name="input_presets"></a> [presets](#input\_presets) | Preset configurations map. Select with repositories[*].preset; falls back to 'default'. | <pre>map(object({<br/>    visibility              = optional(string)<br/>    default_branch          = optional(string)<br/>    topics                  = optional(list(string), [])<br/>    properties              = optional(map(string), {})<br/>    protected_branches      = optional(list(string))<br/>    allow_bypass            = optional(list(string), [])<br/>    required_approvals      = optional(number)<br/>    required_checks         = optional(list(string))<br/>    prevent_force_push      = optional(bool)<br/>    prevent_branch_deletion = optional(bool)<br/>  }))</pre> | <pre>{<br/>  "default": {}<br/>}</pre> | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Map of repositories to create. The map key is a stable identifier (won't trigger recreation). Use 'name' field to rename repositories safely. | <pre>map(object({<br/>    # Optional preset to apply (defaults to "default")<br/>    preset = optional(string, "default")<br/><br/>    # Optional explicit name (allows renaming without Terraform recreation)<br/>    name = optional(string)<br/><br/>    # Core configuration (can override preset)<br/>    description    = optional(string)<br/>    visibility     = optional(string)<br/>    default_branch = optional(string)<br/>    topics         = optional(list(string))<br/>    properties     = optional(map(string))<br/><br/>    # Template<br/>    is_template = optional(bool)<br/>    template = optional(object({<br/>      repository           = string<br/>      include_all_branches = optional(bool, false)<br/>    }))<br/><br/>    # Access & Permissions<br/>    permissions = optional(map(string))<br/>    deploy_keys = optional(map(object({<br/>      key       = string<br/>      read_only = optional(bool, false)<br/>    })))<br/>    allowed_roles = optional(list(string))<br/><br/>    # Automation (Global)<br/>    webhooks = optional(map(object({<br/>      url    = string<br/>      events = list(string)<br/>      secret = optional(string)<br/>    })))<br/>    repository_secrets = optional(map(object({<br/>      value     = string<br/>      sensitive = optional(bool, true)<br/>    })))<br/>    repository_variables = optional(map(string))<br/><br/>    # CI/CD Environments<br/>    environments = optional(map(object({<br/>      required_approvers = optional(list(string), [])<br/>      secrets            = optional(map(string))<br/>      variables          = optional(map(string))<br/>    })))<br/><br/>    # Branch Protection (flattened overrides)<br/>    protected_branches      = optional(list(string))<br/>    allow_bypass            = optional(list(string))<br/>    required_approvals      = optional(number)<br/>    required_checks         = optional(list(string))<br/>    prevent_force_push      = optional(bool)<br/>    prevent_branch_deletion = optional(bool)<br/>  }))</pre> | n/a | yes |
| <a name="input_repository_naming"></a> [repository\_naming](#input\_repository\_naming) | sprintf-style format string for repository names. Use a single '%s' placeholder for the repository key. Example: '%s' (no prefix), 'myorg-%s' (with prefix). | `string` | `"%s"` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | workspace/namespace name for logical grouping of repositories. Will be stored as a custom property on each repository. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_organization"></a> [organization](#output\_organization) | The GitHub organization name. |
| <a name="output_repositories"></a> [repositories](#output\_repositories) | Map of repository keys to their full output details from the repository module. |
| <a name="output_repository_names"></a> [repository\_names](#output\_repository\_names) | Map of repository keys to their GitHub names. |
| <a name="output_repository_urls"></a> [repository\_urls](#output\_repository\_urls) | Map of repository keys to their HTML URLs. |
| <a name="output_workspace"></a> [workspace](#output\_workspace) | The workspace name applied to all repositories. |
<!-- END_TF_DOCS -->
