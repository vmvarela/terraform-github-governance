# GitHub Repository Governance Module

[![Terraform Version](https://img.shields.io/badge/terraform-%3E%3D1.6-623CE4?logo=terraform)](https://www.terraform.io)
[![GitHub Provider](https://img.shields.io/badge/provider-github%20~%3E%206.0-181717?logo=github)](https://registry.terraform.io/providers/integrations/github/latest)
[![Tests](https://img.shields.io/badge/tests-14%20passed-success?logo=terraform)](./tests/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://pre-commit.com/)

A Terraform module for managing GitHub repositories at scale with configurable presets, standardized naming patterns, and secure branch protection defaults.

## Features

- **Preset System**: Reusable configurations you define once and apply per repository
- **Standardized Naming**: Apply organization-wide naming patterns with `repository_naming`
- **Safe Renaming**: Rename repositories without Terraform resource recreation
- **Branch Protection**: Flat, intuitive configuration with automatic code owner review enforcement
- **Performance Optimization**: Pre-fetches team and app IDs to avoid repeated GitHub API calls
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
- GitHub Provider = 6.8.1

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.


---

## Acknowledgments

- Built with [Terraform](https://www.terraform.io/) and the [GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest)
- Uses [terraform-docs](https://terraform-docs.io/) for documentation generation
- Testing with native [Terraform Test](https://developer.hashicorp.com/terraform/language/tests)

---

**Made with ❤️ by [Victor Varela](https://github.com/vmvarela)**
