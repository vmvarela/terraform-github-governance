# Terraform GitHub Governance Module

[![Terraform Version](https://img.shields.io/badge/terraform-%3E%3D1.6-623CE4?logo=terraform)](https://www.terraform.io)
[![GitHub Provider](https://img.shields.io/badge/provider-github%20~%3E%206.0-181717?logo=github)](https://registry.terraform.io/providers/integrations/github/latest)
[![Tests](https://img.shields.io/badge/tests-24%20passed-success?logo=terraform)](./tests/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://pre-commit.com/)

A comprehensive Terraform module for applying consistent governance to GitHub organizations and their repositories. Supports both **organization-wide** and **project-scoped** management with automatic validation and plan-aware feature detection.

## ✨ Features

- 🏢 **Dual Mode Support**: Organization-wide or project-scoped management
- 🔒 **Security First**: Advanced security defaults, secret scanning, Dependabot
- 🤖 **GitHub Actions**: Runner groups, workflows, variables, and encrypted secrets
- 📋 **Governance**: Organization webhooks, custom roles, and rulesets
- ✅ **Plan-Aware**: Automatic validation based on your GitHub plan (Free/Team/Business/Enterprise)
- 🧪 **Fully Tested**: 24 unit tests with 100% pass rate using native Terraform testing
- 📦 **Embedded Submodules**: Includes repository and actions-runner-scale-set modules

---

## 🚀 Quick Start

### Basic Usage (Organization Mode)

```hcl
module "github_governance" {
  source  = "vmvarela/governance/github"
  version = "~> 0.1"

  name          = "my-organization"
  billing_email = "billing@example.com"
  mode          = "organization"

  # Organization settings
  settings = {
    description                 = "My awesome organization"
    default_repository_permission = "read"
    members_can_create_repositories = true
    web_commit_signoff_required = true
  }

  # Repositories
  repositories = {
    "backend-api" = {
      description = "Backend API service"
      visibility  = "private"
      has_issues  = true
    }
    "frontend-app" = {
      description = "Frontend application"
      visibility  = "private"
      has_issues  = true
    }
  }

  # GitHub Actions runner groups
  runner_groups = {
    "default" = {
      visibility = "all"
    }
  }

  # Organization variables
  variables = {
    "ENVIRONMENT" = "production"
    "REGION"      = "us-west-2"
  }
}
```

### Project Mode Example

Perfect for managing a specific project within a larger organization:

```hcl
module "project_x" {
  source  = "vmvarela/governance/github"
  version = "~> 1.0"

  name       = "project-x"
  mode       = "project"
  github_org = "my-organization"
  spec       = "project-x-%s"  # Prefix for all repos

  repositories = {
    "backend"  = { description = "Project X Backend" }
    "frontend" = { description = "Project X Frontend" }
  }

  # Runner groups automatically scoped to project repos
  runner_groups = {
    "ci-runners" = {}
  }
}
```

**👉 See complete examples in [`examples/`](./examples/):**
- [`simple/`](./examples/simple/) - Minimal configuration to get started
- [`complete/`](./examples/complete/) - Comprehensive example with all features

---

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Features](#-features)
- [Examples](#examples)
- [Submodules](#submodules)
- [Architecture](#-architecture) 📊
- [Prerequisites](#prerequisites)
- [Plan Requirements](#plan-requirements-and-limitations)
- [Advanced Features](#advanced-features)
- [Requirements](#requirements) *(auto-generated)*
- [Providers](#providers) *(auto-generated)*
- [Inputs](#inputs) *(auto-generated)*
- [Outputs](#outputs) *(auto-generated)*
- [Troubleshooting](#-troubleshooting) 🔧
- [Performance & Scale](#-performance--scale) ⚡
- [Contributing](./CONTRIBUTING.md)
- [License](#license)

---

## 📊 Architecture

The module supports two operational modes with different scopes and capabilities:

```
┌─────────────────────────────────────────────────────────────┐
│  Terraform GitHub Governance Module                         │
│                                                               │
│  ┌──────────────┐              ┌──────────────┐            │
│  │ Organization │              │   Project    │            │
│  │     Mode     │              │     Mode     │            │
│  │              │              │              │            │
│  │ • Full org   │              │ • Scoped to  │            │
│  │   access     │              │   spec       │            │
│  │ • Webhooks   │              │ • Auto-scope │            │
│  │ • Rulesets   │              │   runners    │            │
│  │ • Any repos  │              │ • Isolated   │            │
│  └──────────────┘              └──────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

**📖 View detailed diagrams:** [Architecture Documentation](./docs/ARCHITECTURE.md)
- Module architecture and data flow
- Plan-based feature availability
- Mode comparison
- Testing architecture
- CI/CD integration

---

## Prerequisites

### Initial Setup: Import Existing Organization

**Important:** Before your first `terraform apply`, you must import the existing GitHub organization settings resource to avoid conflicts:

```bash
# Import organization settings (replace 'your-org-name' with your actual organization name)
terraform import 'module.github.github_organization_settings.this[0]' your-org-name
```

**Why is this needed?**
- GitHub organizations already exist before Terraform manages them
- The `github_organization_settings` resource manages organization-level settings
- Without importing, Terraform will try to create it and fail with a `422` error
- You only need to do this **once** per organization

**When to import:**
- First time using this module with an existing organization
- When you see errors like: `Error: POST https://api.github.com/orgs/your-org 422`

### Required GitHub Token Scopes

This module requires a GitHub Personal Access Token (PAT) with the following scopes:

| Scope | Required | Purpose |
|-------|----------|---------|
| `admin:org` | ✅ Yes | Manage organization settings, webhooks, secrets, variables |
| `repo` | ✅ Yes | Manage repositories, branches, and repository settings |
| `workflow` | ✅ Yes | Manage GitHub Actions workflows and runner groups |
| `read:packages` | ⚠️ Recommended | Read package metadata (if using GitHub Packages) |

**Note:** The `github_organization` data source used for plan validation works with the `admin:org` scope. No additional scopes like `user:email` or `read:user` are required.

### Creating a GitHub Token

1. Go to **GitHub Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token** (classic)
3. Select the required scopes listed above
4. Set an appropriate expiration date
5. Generate and securely store the token

**Security Best Practice:** Use the token via environment variable:
```bash
export TF_VAR_github_token="your_token_here"
```

## Plan Requirements and Limitations

This module includes automatic validation to detect when you're trying to use features that require paid GitHub plans. You'll receive clear warnings during `terraform plan` if your organization plan doesn't support certain features.

### Resources Requiring GitHub Team or Business Plan

The following features are **NOT available** on GitHub Free organizations:

| Feature | Variable | Required Plan | Terraform Resource |
|---------|----------|---------------|-------------------|
| **Organization Webhooks** | `webhooks` | Team/Business/Enterprise | `github_organization_webhook` |
| **Organization Rulesets** | `rulesets` | Team/Business/Enterprise | `github_organization_ruleset` |

**What happens if you use these on Free plan:**
- The module will show a **warning** during `terraform plan` with clear error messages
- The `terraform apply` will fail with a `404 Not Found` error from GitHub API
- You'll see guidance on alternatives or upgrade paths

**Solutions for Free organizations:**
1. **Webhooks**: Use repository-level webhooks (configure in each repository's settings)
2. **Rulesets**: Use repository-level branch protection rules instead

### Resources Requiring GitHub Enterprise Plan

| Feature | Variable | Required Plan | Terraform Resource |
|---------|----------|---------------|-------------------|
| **Custom Repository Roles** | `repository_roles` | Enterprise | `github_organization_repository_role` |

**What happens if you use this without Enterprise:**
- Warning during `terraform plan`
- API will reject the request with appropriate error

**Solution for non-Enterprise organizations:**
- Use standard GitHub roles: `read`, `triage`, `write`, `maintain`, `admin`

### Example Validation Warning

When using a feature that requires a paid plan, you'll see:

```
Warning: Check block assertion failed

  on main.tf line 144, in check "organization_plan_validation":
 144:     condition = length(var.webhooks) == 0 || local.github_plan != "free"

❌ Organization webhooks require GitHub Team, Business, or Enterprise plan.
Current plan: free

Solutions:
  1. Remove the 'webhooks' configuration from your module
  2. Use repository-level webhooks instead (configure in each repository)
  3. Upgrade your organization plan at: https://github.com/organizations/your-org/settings/billing

Error occurs at: github_organization_webhook resource
```

### Checking Your Organization Plan

You can verify your organization's plan before applying:

```bash
# Using the provided script
./scripts/check-org-plan.sh your-org-name

# Or manually via API
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/orgs/your-org | jq '.plan.name'
```

## Advanced Features

### Repository References and Scope Management

The module's behavior differs based on the `mode` parameter, affecting which repositories can be referenced:

#### Organization Mode vs Project Mode

| Aspect | Organization Mode | Project Mode |
|--------|------------------|--------------|
| **Scope** | Entire GitHub organization | Filtered subset of repositories |
| **Runner Groups** | Can reference ANY org repository | Automatically use ONLY module repos |
| **Secrets/Variables** | Can be org-wide or selected repos | Always scoped to module repos |
| **Rulesets** | Apply to all repos or custom list | Apply only to module repos |
| **Repository References** | By name or ID from entire org | Only module-managed repos |

#### Using Repository Names in Organization Mode

In organization mode, runner groups and other resources can reference any repository:

```hcl
module "github" {
  source = "vmvarela/governance/github"

  name = "my-org"
  mode = "organization"  # Organization-wide management

  repositories = {
    "backend-api"  = { description = "Backend API" }
    "frontend-app" = { description = "Frontend App" }
  }

  runner_groups = {
    "production" = {
      visibility   = "selected"
      # Can reference ANY repository in the organization
      repositories = [
        "backend-api",      # Managed by this module
        "frontend-app",     # Managed by this module
        "legacy-system",    # Existing repo NOT in this config
        "external-service"  # Another existing repo
      ]
    }
  }
}
```

#### Project Mode: Automatic Repository Scoping

In project mode, all resources are automatically scoped to module-managed repositories:

```hcl
module "project_x" {
  source = "vmvarela/governance/github"

  name       = "project-x"
  mode       = "project"     # Project mode
  github_org = "my-org"      # Parent organization
  spec       = "project-x-%s" # Name prefix

  repositories = {
    "backend"  = { description = "Project X Backend" }
    "frontend" = { description = "Project X Frontend" }
  }

  # Runner groups automatically use project repos only
  runner_groups = {
    "ci-runners" = {
      # 'repositories' field is IGNORED in project mode
      # Automatically includes: project-x-backend, project-x-frontend
    }
  }

  # Secrets/variables automatically scoped to project repos
  variables = {
    "API_KEY" = "value"  # Only visible to project-x-* repos
  }
}
```

**Key Differences:**
- 🔒 **Project mode** enforces strict boundaries - cannot access repos outside the module
- 🌐 **Organization mode** has full access - can reference any org repository
- ⚡ **Project mode** simplifies configuration - no need to specify repositories repeatedly

#### Accessing Repository IDs

Use the `repository_ids` output to get numeric IDs when needed:

```hcl
# Get specific repository ID
output "backend_id" {
  value = module.github.repository_ids["backend-api"]
}

# Use in custom resources
resource "some_external_resource" "example" {
  repository_ids = [
    module.github.repository_ids["backend-api"],
    module.github.repository_ids["frontend-app"]
  ]
}
```

#### Available Outputs

- `repository_ids`: Map of repository names to numeric IDs (all repos in org)
- `repository_names`: Map of repository keys to actual formatted names
- `repositories`: Complete module outputs for all managed repositories

See [`examples/repository-references/`](./examples/repository-references/) for complete examples.

<!-- BEGIN_TF_DOCS -->


## Usage

### Basic Example (Organization Mode)

```hcl
module "github" {
  source  = "vmvarela/governance/github"
  version = "~> 1.0"

  mode = "organization"
  name = "my-organization"

  settings = {
    billing_email = "billing@example.com"
  }

  repositories = {
    "my-app" = {
      description = "My application"
      visibility  = "private"
    }
  }
}
```

### Project Mode Example

```hcl
module "project_x" {
  source  = "vmvarela/governance/github"
  version = "~> 1.0"

  mode       = "project"
  name       = "project-x"
  github_org = "my-organization"
  spec       = "project-x-%s"

  settings = {
    billing_email = "billing@example.com"
  }

  repositories = {
    "backend"  = { description = "Backend API" }
    "frontend" = { description = "Frontend App" }
  }
}
```

## Examples

- [Simple](./examples/simple) - Minimal configuration to get started
- [Complete](./examples/complete) - Comprehensive example with all features
- [Mode Comparison](./examples/mode-comparison) - Organization vs Project modes
- [Repository References](./examples/repository-references) - Working with repository IDs

## Submodules

- [repository](./modules/repository) - Standalone repository management
- [actions-runner-scale-set](./modules/actions-runner-scale-set) - Kubernetes-based GitHub Actions runners

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | 6.7.5 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_actions_runner_scale_set"></a> [actions\_runner\_scale\_set](#module\_actions\_runner\_scale\_set) | ./modules/actions-runner-scale-set | n/a |
| <a name="module_repo"></a> [repo](#module\_repo) | ./modules/repository | n/a |

## Resources

| Name | Type |
|------|------|
| [github_actions_organization_secret.encrypted](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_secret) | resource |
| [github_actions_organization_secret.plaintext](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_secret) | resource |
| [github_actions_organization_variable.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_organization_variable) | resource |
| [github_actions_runner_group.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_runner_group) | resource |
| [github_dependabot_organization_secret.encrypted](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/dependabot_organization_secret) | resource |
| [github_dependabot_organization_secret.plaintext](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/dependabot_organization_secret) | resource |
| [github_organization_custom_role.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_custom_role) | resource |
| [github_organization_ruleset.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_ruleset) | resource |
| [github_organization_settings.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_settings) | resource |
| [github_organization_webhook.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_webhook) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The ID of the project/organization.<br/><br/>- For organization mode: Your GitHub organization name<br/>- For project mode: Your project identifier (used with 'spec')<br/><br/>Example: name = "my-org" or name = "project-x" | `string` | n/a | yes |
| <a name="input_actions_runner_controller"></a> [actions\_runner\_controller](#input\_actions\_runner\_controller) | Actions Runner Controller configuration for scale sets.<br/><br/>Required when using scale\_set in runner\_groups.<br/>The controller manages all scale sets in the cluster.<br/><br/>Example:<br/>  actions\_runner\_controller = {<br/>    name             = "arc"<br/>    namespace        = "arc-systems"<br/>    create\_namespace = true<br/>    version          = "0.13.0"<br/>    github\_token     = var.github\_token  # or use github\_app\_* vars<br/>  } | <pre>object({<br/>    name                       = optional(string, "arc")<br/>    namespace                  = optional(string, "arc-systems")<br/>    create_namespace           = optional(bool, true)<br/>    version                    = optional(string, "0.13.0")<br/>    github_token               = optional(string)<br/>    github_app_id              = optional(number)<br/>    github_app_private_key     = optional(string)<br/>    github_app_installation_id = optional(number)<br/>    private_registry           = optional(string)<br/>    private_registry_username  = optional(string)<br/>    private_registry_password  = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_defaults"></a> [defaults](#input\_defaults) | Repositories default configuration (if empty).<br/><br/>Provides fallback values for repository settings when not explicitly set.<br/><br/>Example:<br/>  defaults = {<br/>    visibility  = "private"<br/>    has\_issues  = true<br/>    auto\_init   = true<br/>  } | `any` | `{}` | no |
| <a name="input_dependabot_copy_secrets"></a> [dependabot\_copy\_secrets](#input\_dependabot\_copy\_secrets) | Copy secrets from organization to repositories for Dependabot.<br/><br/>When true, organization secrets are automatically copied to all repositories<br/>for use by Dependabot.<br/><br/>Example: dependabot\_copy\_secrets = true | `bool` | `false` | no |
| <a name="input_dependabot_secrets"></a> [dependabot\_secrets](#input\_dependabot\_secrets) | ⚠️  DEPRECATED: Organization/Project common Dependabot plaintext secrets to set.<br/><br/>WARNING: Plaintext secrets are stored unencrypted in Terraform state files.<br/>Use dependabot\_secrets\_encrypted instead. | `map(string)` | `null` | no |
| <a name="input_dependabot_secrets_encrypted"></a> [dependabot\_secrets\_encrypted](#input\_dependabot\_secrets\_encrypted) | Organization/Project common Dependabot encrypted secrets to set.<br/><br/>Use GitHub CLI to encrypt:<br/>  gh secret set SECRET\_NAME --app dependabot --body "value"<br/><br/>Example:<br/>  dependabot\_secrets\_encrypted = {<br/>    "NPM\_TOKEN" = "base64\_encrypted\_value"<br/>  } | `map(string)` | `null` | no |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub organization name | `string` | `null` | no |
| <a name="input_info_organization"></a> [info\_organization](#input\_info\_organization) | Info about the organization. If not provided, they will be fetched by the module. | `any` | `null` | no |
| <a name="input_info_repositories"></a> [info\_repositories](#input\_info\_repositories) | All repositories in the organization. If not provided, they will be fetched by the module. | `any` | `null` | no |
| <a name="input_mode"></a> [mode](#input\_mode) | Governance mode: 'project' or 'organization'.<br/><br/>- 'organization': Manage entire GitHub organization with full access<br/>- 'project': Manage a filtered subset with automatic scoping<br/><br/>Example: mode = "organization" | `string` | `"project"` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | Repository configurations map.<br/><br/>Map of repository names to their configuration objects. Each repository<br/>can customize settings like visibility, features, security, and more.<br/><br/>Example:<br/>  repositories = {<br/>    "backend-api" = {<br/>      description = "Backend API service"<br/>      visibility  = "private"<br/>      has\_issues  = true<br/>      topics      = ["api", "backend"]<br/>    }<br/>    "frontend-app" = {<br/>      description = "Frontend application"<br/>      visibility  = "public"<br/>      has\_discussions = true<br/>    }<br/>  } | <pre>map(object({<br/>    alias                                  = optional(string)<br/>    description                            = optional(string)<br/>    homepage                               = optional(string)<br/>    visibility                             = optional(string)<br/>    has_issues                             = optional(bool)<br/>    has_projects                           = optional(bool)<br/>    has_wiki                               = optional(bool)<br/>    has_downloads                          = optional(bool)<br/>    has_discussions                        = optional(bool)<br/>    allow_merge_commit                     = optional(bool)<br/>    allow_squash_merge                     = optional(bool)<br/>    allow_rebase_merge                     = optional(bool)<br/>    allow_auto_merge                       = optional(bool)<br/>    allow_update_branch                    = optional(bool)<br/>    delete_branch_on_merge                 = optional(bool)<br/>    enable_vulnerability_alerts            = optional(bool)<br/>    enable_dependency_graph                = optional(bool)<br/>    enable_advanced_security               = optional(bool)<br/>    enable_secret_scanning                 = optional(bool)<br/>    enable_secret_scanning_push_protection = optional(bool)<br/>    enable_dependabot_security_updates     = optional(bool)<br/>    enable_actions                         = optional(bool)<br/>    archived                               = optional(bool)<br/>    archive_on_destroy                     = optional(bool)<br/>    is_template                            = optional(bool)<br/>    template                               = optional(string)<br/>    template_include_all_branches          = optional(bool)<br/>    gitignore_template                     = optional(string)<br/>    license_template                       = optional(string)<br/>    default_branch                         = optional(string)<br/>    auto_init                              = optional(bool)<br/>    topics                                 = optional(list(string))<br/>    actions_access_level                   = optional(string)<br/>    actions_allowed_policy                 = optional(string)<br/>    actions_allowed_github                 = optional(bool)<br/>    actions_allowed_verified               = optional(bool)<br/>    actions_allowed_patterns               = optional(set(string))<br/>    merge_commit_title                     = optional(string)<br/>    merge_commit_message                   = optional(string)<br/>    squash_merge_commit_title              = optional(string)<br/>    squash_merge_commit_message            = optional(string)<br/>    web_commit_signoff_required            = optional(bool)<br/>    pages_source_branch                    = optional(string)<br/>    pages_source_path                      = optional(string)<br/>    pages_build_type                       = optional(string)<br/>    pages_cname                            = optional(string)<br/><br/>    # Nested configurations<br/>    teams                        = optional(map(string))<br/>    users                        = optional(map(string))<br/>    variables                    = optional(map(string))<br/>    secrets                      = optional(map(string))<br/>    secrets_encrypted            = optional(map(string))<br/>    dependabot_secrets           = optional(map(string))<br/>    dependabot_secrets_encrypted = optional(map(string))<br/>    dependabot_copy_secrets      = optional(bool)<br/><br/>    # Advanced configurations<br/>    autolink_references = optional(map(object({<br/>      key_prefix      = string<br/>      target_url      = string<br/>      is_alphanumeric = optional(bool, true)<br/>    })))<br/>    branches = optional(map(object({<br/>      source_branch = optional(string)<br/>      source_sha    = optional(string)<br/>    })))<br/>    deploy_keys = optional(map(object({<br/>      key       = string<br/>      read_only = optional(bool, true)<br/>    })))<br/>    deploy_keys_path = optional(string)<br/>    environments = optional(map(object({<br/>      wait_timer          = optional(number)<br/>      can_admins_bypass   = optional(bool, true)<br/>      prevent_self_review = optional(bool, false)<br/>      reviewers = optional(object({<br/>        teams = optional(list(number))<br/>        users = optional(list(number))<br/>      }))<br/>      deployment_branch_policy = optional(object({<br/>        protected_branches     = bool<br/>        custom_branch_policies = bool<br/>      }))<br/>    })))<br/>    files               = optional(list(string))<br/>    issue_labels        = optional(map(string))<br/>    issue_labels_colors = optional(map(string))<br/>    rulesets            = optional(map(any))<br/>    webhooks = optional(map(object({<br/>      url          = string<br/>      content_type = string<br/>      events       = list(string)<br/>      active       = optional(bool, true)<br/>      insecure_ssl = optional(bool, false)<br/>      secret       = optional(string)<br/>    })))<br/>    custom_properties       = optional(map(string))<br/>    custom_properties_types = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_repository_roles"></a> [repository\_roles](#input\_repository\_roles) | Custom repository roles for the organization (key: role\_name).<br/><br/>⚠️ REQUIRES: GitHub Enterprise plan<br/><br/>Create custom roles that extend base permissions with specific capabilities.<br/><br/>Example:<br/>  repository\_roles = {<br/>    "deployer" = {<br/>      description = "Can deploy to production"<br/>      base\_role   = "write"<br/>      permissions = ["read", "write", "create\_deployment"]<br/>    }<br/>  } | <pre>map(object({<br/>    description = optional(string)<br/>    base_role   = string<br/>    permissions = set(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_rulesets"></a> [rulesets](#input\_rulesets) | Organization/Project rulesets for branch protection and governance.<br/><br/>⚠️ REQUIRES: GitHub Team or higher plan<br/><br/>Define rules that apply across repositories to enforce consistent workflows,<br/>branch protection, and code quality standards.<br/><br/>Example:<br/>  rulesets = {<br/>    "protect-main" = {<br/>      enforcement = "active"<br/>      rules = {<br/>        pull\_request = {<br/>          required\_approving\_review\_count = 1<br/>        }<br/>        deletion         = true<br/>        non\_fast\_forward = true<br/>      }<br/>    }<br/>  } | <pre>map(object({<br/>    enforcement = optional(string, "active")<br/>    rules = optional(object({<br/>      branch_name_pattern = optional(object({<br/>        operator = optional(string)<br/>        pattern  = optional(string)<br/>        name     = optional(string)<br/>        negate   = optional(bool)<br/>      }))<br/>      commit_author_email_pattern = optional(object({<br/>        operator = optional(string)<br/>        pattern  = optional(string)<br/>        name     = optional(string)<br/>        negate   = optional(bool)<br/>      }))<br/>      commit_message_pattern = optional(object({<br/>        operator = optional(string)<br/>        pattern  = optional(string)<br/>        name     = optional(string)<br/>        negate   = optional(bool)<br/>      }))<br/>      committer_email_pattern = optional(object({<br/>        operator = optional(string)<br/>        pattern  = optional(string)<br/>        name     = optional(string)<br/>        negate   = optional(bool)<br/>      }))<br/>      creation         = optional(bool)<br/>      deletion         = optional(bool)<br/>      non_fast_forward = optional(bool)<br/>      pull_request = optional(object({<br/>        dismiss_stale_reviews_on_push     = optional(bool)<br/>        require_code_owner_review         = optional(bool)<br/>        require_last_push_approval        = optional(bool)<br/>        required_approving_review_count   = optional(number)<br/>        required_review_thread_resolution = optional(bool)<br/>      }))<br/>      required_workflows = optional(list(object({<br/>        repository = string<br/>        path       = string<br/>        ref        = optional(string)<br/>      })))<br/>      required_linear_history              = optional(bool)<br/>      required_signatures                  = optional(bool)<br/>      required_status_checks               = optional(map(string))<br/>      strict_required_status_checks_policy = optional(bool)<br/>      tag_name_pattern = optional(object({<br/>        operator = optional(string)<br/>        pattern  = optional(string)<br/>        name     = optional(string)<br/>        negate   = optional(bool)<br/>      }))<br/>      update = optional(bool)<br/>    }))<br/>    target = optional(string, "branch")<br/>    bypass_actors = optional(map(object({<br/>      actor_type  = string<br/>      bypass_mode = string<br/>    })))<br/>    include      = optional(list(string), [])<br/>    exclude      = optional(list(string), [])<br/>    repositories = optional(list(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_runner_groups"></a> [runner\_groups](#input\_runner\_groups) | Runner groups for GitHub Actions self-hosted runners (key: runner\_group\_name).<br/><br/>Behavior by mode:<br/>- PROJECT MODE: Runner groups automatically include ALL repositories managed by this module.<br/>                The 'repositories' field is IGNORED and 'visibility' is forced to 'selected'.<br/><br/>- ORGANIZATION MODE: Runner groups can reference ANY repository in the organization.<br/>                    The 'repositories' field accepts repository names or numeric IDs.<br/>                    Use 'visibility' to control access (all/private/selected).<br/><br/>Example (organization mode):<br/>  runner\_groups = {<br/>    "production" = {<br/>      visibility   = "selected"<br/>      repositories = ["backend-api", "frontend-app"]  # Repository names<br/>    }<br/>  }<br/><br/>Example (project mode):<br/>  runner\_groups = {<br/>    "ci-runners" = {}  # Automatically uses all project repositories<br/>  } | <pre>map(object({<br/>    visibility                = optional(string, "all")<br/>    workflows                 = optional(set(string))<br/>    repositories              = optional(set(string), [])<br/>    allow_public_repositories = optional(bool)<br/>    scale_set = optional(object({<br/>      namespace        = optional(string, "arc-runners")<br/>      create_namespace = optional(bool, true)<br/>      version          = optional(string, "0.13.0")<br/>      min_runners      = optional(number, 1)<br/>      max_runners      = optional(number, 5)<br/>      runner_image     = optional(string, "ghcr.io/actions/actions-runner:latest")<br/>      pull_always      = optional(bool, true)<br/>      container_mode   = optional(string, "dind")<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | ⚠️  DEPRECATED: Organization/Project common plaintext secrets to set.<br/><br/>WARNING: Plaintext secrets are stored unencrypted in Terraform state files, which is a security risk.<br/><br/>Use secrets\_encrypted instead and encrypt secrets with:<br/>  gh secret set SECRET\_NAME --body "secret\_value"<br/><br/>Or use external secret management:<br/>  - HashiCorp Vault<br/>  - AWS Secrets Manager<br/>  - Azure Key Vault<br/>  - Google Secret Manager | `map(string)` | `null` | no |
| <a name="input_secrets_encrypted"></a> [secrets\_encrypted](#input\_secrets\_encrypted) | Organization/Project common encrypted secrets to set.<br/><br/>Secrets must be encrypted with the organization's public key.<br/>Use GitHub CLI to encrypt:<br/>  gh secret set SECRET\_NAME --body "secret-value"<br/><br/>Example:<br/>  secrets\_encrypted = {<br/>    "DEPLOY\_TOKEN" = "base64\_encrypted\_value"<br/>    "API\_KEY"      = "base64\_encrypted\_value"<br/>  } | `map(string)` | `null` | no |
| <a name="input_settings"></a> [settings](#input\_settings) | Organization and repository settings (immutable configuration that cannot be overwritten by individual repositories).<br/><br/>Comprehensive settings object that controls:<br/>- Organization-level behavior<br/>- Default repository settings<br/>- Security defaults for new repositories<br/><br/>Example:<br/>  settings = {<br/>    description                 = "My organization"<br/>    default\_repository\_permission = "read"<br/>    web\_commit\_signoff\_required = true<br/>    advanced\_security\_enabled\_for\_new\_repositories = true<br/>  } | <pre>object({<br/>    # Organization level settings<br/>    billing_email                                                = optional(string)<br/>    description                                                  = optional(string)<br/>    display_name                                                 = optional(string)<br/>    company                                                      = optional(string)<br/>    blog                                                         = optional(string)<br/>    email                                                        = optional(string)<br/>    location                                                     = optional(string)<br/>    twitter_username                                             = optional(string)<br/>    default_repository_permission                                = optional(string)<br/>    has_organization_projects                                    = optional(bool)<br/>    has_repository_projects                                      = optional(bool)<br/>    members_can_create_repositories                              = optional(bool)<br/>    members_can_create_private_repositories                      = optional(bool)<br/>    members_can_create_public_repositories                       = optional(bool)<br/>    members_can_create_internal_repositories                     = optional(bool)<br/>    members_can_create_pages                                     = optional(bool)<br/>    members_can_create_public_pages                              = optional(bool)<br/>    members_can_create_private_pages                             = optional(bool)<br/>    members_can_fork_private_repositories                        = optional(bool)<br/>    web_commit_signoff_required                                  = optional(bool)<br/>    dependabot_alerts_enabled_for_new_repositories               = optional(bool)<br/>    dependabot_security_updates_enabled_for_new_repositories     = optional(bool)<br/>    dependency_graph_enabled_for_new_repositories                = optional(bool)<br/>    advanced_security_enabled_for_new_repositories               = optional(bool)<br/>    secret_scanning_enabled_for_new_repositories                 = optional(bool)<br/>    secret_scanning_push_protection_enabled_for_new_repositories = optional(bool)<br/><br/>    # Repository level settings (applied to all repositories)<br/>    has_projects                           = optional(bool)<br/>    has_wiki                               = optional(bool)<br/>    has_issues                             = optional(bool)<br/>    has_downloads                          = optional(bool)<br/>    has_discussions                        = optional(bool)<br/>    allow_merge_commit                     = optional(bool)<br/>    allow_squash_merge                     = optional(bool)<br/>    allow_rebase_merge                     = optional(bool)<br/>    allow_auto_merge                       = optional(bool)<br/>    allow_update_branch                    = optional(bool)<br/>    delete_branch_on_merge                 = optional(bool)<br/>    enable_vulnerability_alerts            = optional(bool)<br/>    enable_dependency_graph                = optional(bool)<br/>    enable_advanced_security               = optional(bool)<br/>    enable_secret_scanning                 = optional(bool)<br/>    enable_secret_scanning_push_protection = optional(bool)<br/>    enable_dependabot_security_updates     = optional(bool)<br/>    enable_actions                         = optional(bool)<br/>    is_template                            = optional(bool)<br/>    archived                               = optional(bool)<br/>    archive_on_destroy                     = optional(bool)<br/>    homepage                               = optional(string)<br/>    visibility                             = optional(string)<br/>    template                               = optional(string)<br/>    template_include_all_branches          = optional(bool)<br/>    gitignore_template                     = optional(string)<br/>    license_template                       = optional(string)<br/>    default_branch                         = optional(string)<br/>    auto_init                              = optional(bool)<br/>    actions_access_level                   = optional(string)<br/>    actions_allowed_policy                 = optional(string)<br/>    actions_allowed_github                 = optional(bool)<br/>    actions_allowed_verified               = optional(bool)<br/>    actions_allowed_patterns               = optional(set(string))<br/>    merge_commit_title                     = optional(string)<br/>    merge_commit_message                   = optional(string)<br/>    squash_merge_commit_title              = optional(string)<br/>    squash_merge_commit_message            = optional(string)<br/>    web_commit_signoff_required_repo       = optional(bool)<br/>    pages_source_branch                    = optional(string)<br/>    pages_source_path                      = optional(string)<br/>    pages_build_type                       = optional(string)<br/>    pages_cname                            = optional(string)<br/><br/>    # Nested configurations<br/>    variables = optional(map(string), {})<br/>    users     = optional(map(string), {})<br/>    teams     = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_spec"></a> [spec](#input\_spec) | Format specification for repository names (i.e "prefix-%s") | `string` | `null` | no |
| <a name="input_teams"></a> [teams](#input\_teams) | The list of collaborators (teams) of all repositories, and their role | `map(string)` | `{}` | no |
| <a name="input_users"></a> [users](#input\_users) | The list of collaborators (users) of all repositories, and their role | `map(string)` | `{}` | no |
| <a name="input_variables"></a> [variables](#input\_variables) | Organization/Project common variables to set | `map(string)` | `null` | no |
| <a name="input_webhooks"></a> [webhooks](#input\_webhooks) | Organization webhooks configuration (key: webhook\_name).<br/><br/>⚠️ REQUIRES: GitHub Team or higher plan<br/><br/>Organization webhooks notify external services about events across all repositories.<br/>For Free plans, use repository-level webhooks instead.<br/><br/>Example:<br/>  webhooks = {<br/>    "ci-notifications" = {<br/>      url          = "https://ci.example.com/webhook"<br/>      content\_type = "json"<br/>      events       = ["push", "pull\_request"]<br/>    }<br/>    "security-alerts" = {<br/>      url          = "https://security.example.com/webhook"<br/>      content\_type = "json"<br/>      secret       = "webhook\_secret"<br/>      events       = ["code\_scanning\_alert", "dependabot\_alert"]<br/>    }<br/>  } | <pre>map(object({<br/>    active       = optional(bool, true)<br/>    url          = string<br/>    content_type = string<br/>    insecure_ssl = optional(bool, false)<br/>    secret       = optional(string, null)<br/>    events       = list(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_custom_role_ids"></a> [custom\_role\_ids](#output\_custom\_role\_ids) | Map of custom repository role names to their IDs (Enterprise only) |
| <a name="output_features_available"></a> [features\_available](#output\_features\_available) | Features available based on current organization plan |
| <a name="output_governance_summary"></a> [governance\_summary](#output\_governance\_summary) | Complete governance posture summary |
| <a name="output_organization_id"></a> [organization\_id](#output\_organization\_id) | GitHub organization ID |
| <a name="output_organization_plan"></a> [organization\_plan](#output\_organization\_plan) | Current GitHub organization plan (free, team, business, enterprise) |
| <a name="output_organization_settings"></a> [organization\_settings](#output\_organization\_settings) | Organization settings |
| <a name="output_organization_settings_summary"></a> [organization\_settings\_summary](#output\_organization\_settings\_summary) | Organization settings configuration summary |
| <a name="output_repositories"></a> [repositories](#output\_repositories) | Repositories managed by the module (complete module outputs) |
| <a name="output_repositories_security_posture"></a> [repositories\_security\_posture](#output\_repositories\_security\_posture) | Security configuration summary across all repositories |
| <a name="output_repositories_summary"></a> [repositories\_summary](#output\_repositories\_summary) | Summary statistics of repositories managed by this module |
| <a name="output_repository_ids"></a> [repository\_ids](#output\_repository\_ids) | Map of all repository names to their IDs (numeric).<br/>Includes both repositories managed by this module and existing repositories in the organization.<br/>Useful for referencing repositories in rulesets, runner groups, and other resources.<br/><br/>Usage example in rulesets:<br/>  selected\_repository\_ids = [<br/>    module.github.repository\_ids["my-repo"],<br/>    module.github.repository\_ids["another-repo"]<br/>  ] |
| <a name="output_repository_names"></a> [repository\_names](#output\_repository\_names) | Map of repository keys to their actual names (after applying spec formatting) |
| <a name="output_ruleset_ids"></a> [ruleset\_ids](#output\_ruleset\_ids) | Map of organization ruleset names to their IDs |
| <a name="output_runner_group_ids"></a> [runner\_group\_ids](#output\_runner\_group\_ids) | Map of runner group names to their IDs |
| <a name="output_runner_groups_summary"></a> [runner\_groups\_summary](#output\_runner\_groups\_summary) | Summary of runner groups and scale sets deployment |
| <a name="output_webhook_ids"></a> [webhook\_ids](#output\_webhook\_ids) | Map of organization webhook names to their IDs |
<!-- END_TF_DOCS -->

---

## 🔧 Troubleshooting

### Common Errors and Solutions

#### Error Code: TF-GH-001 - Organization Webhooks Not Available

**Error Message:**
```
[TF-GH-001] Organization webhooks require GitHub Team, Business, or Enterprise plan.
```

**Cause:** Your organization is on the Free plan, which doesn't support organization-level webhooks.

**Solutions:**
1. **Use repository-level webhooks** - Configure webhooks per repository in the module:
   ```hcl
   repositories = {
     "my-repo" = {
       webhooks = {
         "ci" = {
           url          = "https://ci.example.com/webhook"
           content_type = "json"
           events       = ["push", "pull_request"]
         }
       }
     }
   }
   ```

2. **Remove organization webhooks** from your configuration
3. **Upgrade your plan** at GitHub billing settings

---

#### Error Code: TF-GH-002 - Organization Rulesets Not Available

**Error Message:**
```
[TF-GH-002] Organization rulesets require GitHub Team, Business, or Enterprise plan.
```

**Cause:** Organization rulesets are only available on paid plans.

**Solutions:**
1. **Use repository-level branch protection:**
   ```hcl
   repositories = {
     "my-repo" = {
       branch_protections = {
         "main" = {
           required_approving_review_count = 1
           enforce_admins                  = true
         }
       }
     }
   }
   ```

2. **Remove `rulesets`** from module configuration
3. **Upgrade to Team or higher** plan

---

#### Error Code: TF-GH-003 - Custom Repository Roles Not Available

**Error Message:**
```
[TF-GH-003] Custom repository roles require GitHub Enterprise plan.
```

**Cause:** Custom roles are an Enterprise-only feature.

**Solutions:**
1. **Use standard GitHub roles:**
   - `read` - Can read and clone repositories
   - `triage` - Can read and manage issues/PRs
   - `write` - Can push to repositories
   - `maintain` - Can manage repositories without access to sensitive actions
   - `admin` - Full administrative access

2. **Remove `repository_roles`** configuration
3. **Upgrade to Enterprise** plan

---

#### Error Code: TF-GH-004 - Internal Repositories Not Available

**Error Message:**
```
[TF-GH-004] Internal repositories require GitHub Business or Enterprise plan.
```

**Cause:** Internal visibility is only available on Business and Enterprise plans.

**Solutions:**
1. **Change repository visibility** to `private` or `public`:
   ```hcl
   repositories = {
     "my-repo" = {
       visibility = "private"  # Changed from "internal"
     }
   }
   ```

2. **Upgrade to Business or Enterprise** plan

---

#### Error Code: TF-GH-005 - Runner Group Configuration Error

**Error Message:**
```
[TF-GH-005] Runner groups with visibility='selected' must have at least one repository specified.
```

**Cause:** You configured a runner group with `visibility = "selected"` but didn't specify any repositories.

**Solutions:**
1. **Add repositories to the runner group:**
   ```hcl
   runner_groups = {
     "production" = {
       visibility   = "selected"
       repositories = ["backend-api", "frontend-app"]  # Add repos
     }
   }
   ```

2. **Change visibility** to `"all"` or `"private"`:
   ```hcl
   runner_groups = {
     "production" = {
       visibility = "all"  # No repositories specification needed
     }
   }
   ```

---

#### Error Code: TF-GH-006/007 - Plaintext Secrets Deprecated

**Error Message:**
```
[TF-GH-006] Plaintext secrets are deprecated and disabled for security reasons.
```

**Cause:** Storing plaintext secrets in Terraform state is a security risk.

**Solutions:**
1. **Use encrypted secrets** with GitHub CLI:
   ```bash
   # Encrypt organization secret
   gh secret set DEPLOY_TOKEN --body "my-secret-value"

   # Encrypt Dependabot secret
   gh secret set NPM_TOKEN --app dependabot --body "npm-token"
   ```

2. **Update your configuration:**
   ```hcl
   # ❌ Don't use this
   secrets = {
     "API_KEY" = "plaintext-value"
   }

   # ✅ Use this instead
   secrets_encrypted = {
     "API_KEY" = "encrypted_base64_value"
   }
   ```

3. **Use external secret management:**
   - HashiCorp Vault
   - AWS Secrets Manager
   - Azure Key Vault
   - Google Secret Manager

---

### General Troubleshooting Tips

#### 422 Error on Organization Settings

**Problem:** `Error: POST https://api.github.com/orgs/your-org 422`

**Solution:** Import existing organization settings first:
```bash
terraform import 'module.github.github_organization_settings.this[0]' your-org-name
```

---

#### Rate Limiting Issues

**Problem:** `Error: API rate limit exceeded`

**Solutions:**
1. **Use a PAT with higher rate limits** (authenticated requests: 5000/hour)
2. **Add delays between operations** using `time_sleep` resources
3. **Reduce parallelism:**
   ```bash
   terraform apply -parallelism=5
   ```

---

#### State Management for Large Organizations

**Problem:** Slow terraform operations with 100+ repositories

**Solutions:**
1. **Use targeted operations:**
   ```bash
   terraform apply -target=module.github.github_repository.this[\"specific-repo\"]
   ```

2. **Split into multiple modules** by team or project
3. **Use Terraform Cloud/Enterprise** for better state management
4. **Enable partial state refresh:**
   ```bash
   terraform apply -refresh=false
   ```

---

#### Module Import Failures

**Problem:** Cannot import existing resources

**Solutions:**
1. **Check resource IDs** - Most GitHub resources use numeric IDs
2. **Verify permissions** - Ensure your token has required scopes
3. **Use correct import syntax:**
   ```bash
   # Repository
   terraform import 'module.github.module.repo[\"my-repo\"].github_repository.this[0]' my-repo

   # Organization settings
   terraform import 'module.github.github_organization_settings.this[0]' org-name
   ```

---

### Getting Help

If you encounter issues not covered here:

1. **Check the error code** (TF-GH-XXX) in the error message
2. **Review documentation links** provided in error messages
3. **Search existing issues** on [GitHub](https://github.com/vmvarela/terraform-github-governance/issues)
4. **Open a new issue** with:
   - Terraform version
   - Module version
   - Error code and full error message
   - Relevant configuration (sanitized)
   - Steps to reproduce

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](./CONTRIBUTING.md) for details on:

- Development setup and prerequisites
- Running tests (`terraform test`, `make test`)
- Code style and formatting
- Commit message conventions (Conventional Commits)
- Pull request process

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## ⚡ Performance & Scale

For managing large organizations (50+ repositories) or high-frequency operations, see our comprehensive guides:

### 📚 Documentation

- **[Performance Optimization Guide](./docs/PERFORMANCE.md)** - Strategies for large-scale deployments
  - Workspace segmentation strategies
  - API rate limit management
  - State optimization techniques
  - Parallel execution best practices
  - Resource limits and recommendations

- **[Error Code Reference](./docs/ERROR_CODES.md)** - Complete error code documentation
  - All error codes (TF-GH-001 through TF-GH-999)
  - Detailed solutions and examples
  - Quick reference for troubleshooting

### 🎯 Quick Performance Tips

**For organizations with 50+ repositories:**
- Split into multiple workspaces (50-100 repos each)
- Use remote state with locking
- Adjust parallelism: `terraform apply -parallelism=5`
- Implement targeted applies for specific changes

**For high-frequency operations:**
- Monitor GitHub API rate limits
- Use `-refresh=false` when appropriate
- Implement workspace separation by team/project
- Consider CI/CD pipeline optimization

See the [Performance Guide](./docs/PERFORMANCE.md) for detailed strategies and examples.

---

## 🙏 Acknowledgments

- Built with [Terraform](https://www.terraform.io/) and the [GitHub Provider](https://registry.terraform.io/providers/integrations/github/latest)
- Uses [terraform-docs](https://terraform-docs.io/) for documentation generation
- Testing with native [Terraform Test](https://developer.hashicorp.com/terraform/language/tests)

---

**Made with ❤️ by [Victor Varela](https://github.com/vmvarela)**
