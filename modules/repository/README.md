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
| `github_team_ids` | map(number) | **Yes** | `{}` | Team IDs map (slug → ID) for branch bypass actors and environment approvers. Must be provided by parent module. |
| `github_user_ids` | map(number) | **Yes** | `{}` | User IDs map (login → ID) for environment approvers. Must be provided by parent module. |
| `github_app_ids` | map(number) | **Yes** | `{}` | App IDs map (slug → installation ID) for branch bypass actors. Must be provided by parent module. |

**Important**:
- This module is designed to be called exclusively from the parent governance module, which pre-fetches all team, user, and app IDs.
- The module **does not** perform any data source lookups (`data.github_team`, `data.github_user`, `data.github_app`) - all IDs must be provided.
- This design enables the parent module to optimize API calls and prevents duplicate lookups across multiple repository instances.

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

### v2.0 - Data Source Removal

**Important**: This module now requires all team, user, and app IDs to be provided by the parent module:

- **Removed**: `data.github_team`, `data.github_user`, `data.github_app` data sources
- **Required**: `github_team_ids`, `github_user_ids`, `github_app_ids` variables must be provided
- **Rationale**: Enables the parent module to optimize API calls and prevent duplicate lookups

If you were using this module standalone, you must now fetch IDs yourself:

```hcl
# Fetch IDs before calling the module
data "github_team" "platform" {
  slug = "platform"
}

module "repository" {
  source = "./modules/repository"

  name = "my-repo"

  # Must provide IDs explicitly
  github_team_ids = {
    platform = data.github_team.platform.id
  }
  github_user_ids = {}
  github_app_ids  = {}

  allow_bypass = ["team:platform"]
}
```

### v1.x - Environment Protection Simplification

Recent simplification of environment protection:

- Removed nested `protection_rules` object; use flat `required_approvers` directly inside each environment.
- Removed `wait_timer_minutes` (grace period not supported in current implementation).
- Renamed performance optimization variables: `allow_bypass_team_ids` → `github_team_ids`, `allow_bypass_app_ids` → `github_app_ids` for consistency.
- `required_approvers` supports both team reviewers (`team:<slug>`) and user reviewers (`user:<login>`).
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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | 6.8.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [github_actions_environment_secret.env_secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_secret) | resource |
| [github_actions_environment_variable.env_var](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable) | resource |
| [github_actions_secret.repo_secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_variable.repo_var](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_repository.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) | resource |
| [github_repository_collaborators.all](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_collaborators) | resource |
| [github_repository_custom_property.property](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_custom_property) | resource |
| [github_repository_custom_property.workspace](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_custom_property) | resource |
| [github_repository_deploy_key.deploy_key](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_deploy_key) | resource |
| [github_repository_environment.env](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment) | resource |
| [github_repository_ruleset.ruleset](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |
| [github_repository_webhook.webhook](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_webhook) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_bypass"></a> [allow\_bypass](#input\_allow\_bypass) | Actors allowed to bypass protections: 'org-admin', 'role:maintain\|write\|admin', 'team:slug', 'app:slug'. | `list(string)` | `[]` | no |
| <a name="input_allowed_roles"></a> [allowed\_roles](#input\_allowed\_roles) | List of allowed repository roles. Empty list disables validation. Defaults to GitHub built-in roles. | `list(string)` | <pre>[<br/>  "pull",<br/>  "triage",<br/>  "push",<br/>  "maintain",<br/>  "admin"<br/>]</pre> | no |
| <a name="input_default_branch"></a> [default\_branch](#input\_default\_branch) | The name of the main branch (e.g., 'main'). | `string` | `"main"` | no |
| <a name="input_deploy_keys"></a> [deploy\_keys](#input\_deploy\_keys) | Map of deploy keys to add. The map key is the title of the deploy key. | <pre>map(object({<br/>    key       = string # The SSH public key<br/>    read_only = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_description"></a> [description](#input\_description) | A short, friendly description of the repository's purpose. | `string` | `null` | no |
| <a name="input_environments"></a> [environments](#input\_environments) | Defines CI/CD environments (e.g., 'staging', 'production') with optional required\_approvers (teams/users), secrets and variables. Empty or omitted required\_approvers disables reviewer protection. | <pre>map(object({<br/>    required_approvers = optional(list(string), []) # e.g., ["user:login", "team:slug"]<br/>    secrets            = optional(map(string), {})<br/>    variables          = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_github_app_ids"></a> [github\_app\_ids](#input\_github\_app\_ids) | Map of app slug -> app installation ID. Required for branch bypass app actors. Must be provided by parent governance module. | `map(number)` | `{}` | no |
| <a name="input_github_team_ids"></a> [github\_team\_ids](#input\_github\_team\_ids) | Map of team slug -> team ID. Required for branch bypass actors and environment reviewers. Must be provided by parent governance module. | `map(number)` | `null` | no |
| <a name="input_github_user_ids"></a> [github\_user\_ids](#input\_github\_user\_ids) | Map of user login -> user ID. Required for environment reviewers. Must be provided by parent governance module. | `map(number)` | `{}` | no |
| <a name="input_is_template"></a> [is\_template](#input\_is\_template) | Mark this repository as a template repository. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the repository. Must be unique within its workspace (organization, group, or project). | `string` | n/a | yes |
| <a name="input_organization"></a> [organization](#input\_organization) | GitHub organization name where the repository will be created. | `string` | n/a | yes |
| <a name="input_permissions"></a> [permissions](#input\_permissions) | Map of permission grants. Key is the entity ('user:name' or 'team:slug'), Value is the provider-specific role name (e.g., 'write', 'admin', 'my-custom-role'). | `map(string)` | `{}` | no |
| <a name="input_prevent_branch_deletion"></a> [prevent\_branch\_deletion](#input\_prevent\_branch\_deletion) | Prevent deletion of protected branches. | `bool` | `true` | no |
| <a name="input_prevent_force_push"></a> [prevent\_force\_push](#input\_prevent\_force\_push) | Prevent force-pushes (non-fast-forward). | `bool` | `true` | no |
| <a name="input_properties"></a> [properties](#input\_properties) | Generic key-value metadata properties. | `map(string)` | `{}` | no |
| <a name="input_protected_branches"></a> [protected\_branches](#input\_protected\_branches) | Branches to protect. Empty list disables the ruleset. Patterns like 'main', 'release/*'. | `list(string)` | `[]` | no |
| <a name="input_repository_secrets"></a> [repository\_secrets](#input\_repository\_secrets) | Map of secrets at the REPOSITORY level (global). Keys are secret names, values are objects: `{ value = string, sensitive = optional(bool, true) }`. | `map(object({ value = string, sensitive = optional(bool, true) }))` | `{}` | no |
| <a name="input_repository_variables"></a> [repository\_variables](#input\_repository\_variables) | Map of variables at the REPOSITORY level (global). | `map(string)` | `{}` | no |
| <a name="input_required_approvals"></a> [required\_approvals](#input\_required\_approvals) | Number of required PR approvals. 0 disables PR requirement. | `number` | `1` | no |
| <a name="input_required_checks"></a> [required\_checks](#input\_required\_checks) | List of required status check contexts. Strict policy is always enforced. | `list(string)` | `[]` | no |
| <a name="input_template"></a> [template](#input\_template) | Create this repository from a template repository. Use 'owner/repo' format. | <pre>object({<br/>    repository           = string # "owner/repo" format<br/>    include_all_branches = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_topics"></a> [topics](#input\_topics) | A list of GitHub topics to classify the repository. | `list(string)` | `[]` | no |
| <a name="input_visibility"></a> [visibility](#input\_visibility) | Visibility of the repository. Valid values: 'public', 'private', or 'internal'. | `string` | `"private"` | no |
| <a name="input_webhooks"></a> [webhooks](#input\_webhooks) | Map of webhooks to configure. Key is the webhook name. | <pre>map(object({<br/>    url    = string<br/>    events = list(string) # Generic events: 'push', 'pull_request', 'issue'<br/>    secret = optional(string, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | Optional workspace/namespace for logical grouping of repositories. If provided, will be stored as a custom property. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_branch"></a> [default\_branch](#output\_default\_branch) | The name of the default branch of the repository |
| <a name="output_deploy_keys_count"></a> [deploy\_keys\_count](#output\_deploy\_keys\_count) | Number of deploy keys created |
| <a name="output_environments_count"></a> [environments\_count](#output\_environments\_count) | Number of environments created |
| <a name="output_full_name"></a> [full\_name](#output\_full\_name) | A string of the form 'orgname/reponame' |
| <a name="output_html_url"></a> [html\_url](#output\_html\_url) | URL to the repository on the web |
| <a name="output_http_clone_url"></a> [http\_clone\_url](#output\_http\_clone\_url) | URL that can be provided to git clone to clone the repository via HTTPS |
| <a name="output_id"></a> [id](#output\_id) | The ID of the created repository |
| <a name="output_name"></a> [name](#output\_name) | The name of the created repository |
| <a name="output_node_id"></a> [node\_id](#output\_node\_id) | GraphQL global node id for use with v4 API |
| <a name="output_organization"></a> [organization](#output\_organization) | The GitHub organization name |
| <a name="output_properties"></a> [properties](#output\_properties) | The custom properties assigned to the repository |
| <a name="output_properties_count"></a> [properties\_count](#output\_properties\_count) | Number of custom properties created |
| <a name="output_protected_branches_ruleset_created"></a> [protected\_branches\_ruleset\_created](#output\_protected\_branches\_ruleset\_created) | Whether a protected-branches ruleset was created |
| <a name="output_protected_branches_ruleset_id"></a> [protected\_branches\_ruleset\_id](#output\_protected\_branches\_ruleset\_id) | ID of the created protected-branches ruleset (if any) |
| <a name="output_repository_full_name"></a> [repository\_full\_name](#output\_repository\_full\_name) | A string of the form 'orgname/reponame' |
| <a name="output_repository_id"></a> [repository\_id](#output\_repository\_id) | The ID of the created repository |
| <a name="output_repository_name"></a> [repository\_name](#output\_repository\_name) | The name of the created repository |
| <a name="output_repository_secrets_count"></a> [repository\_secrets\_count](#output\_repository\_secrets\_count) | Number of repository secrets |
| <a name="output_repository_variables_count"></a> [repository\_variables\_count](#output\_repository\_variables\_count) | Number of repository variables |
| <a name="output_ssh_clone_url"></a> [ssh\_clone\_url](#output\_ssh\_clone\_url) | URL that can be provided to git clone to clone the repository via SSH |
| <a name="output_topics"></a> [topics](#output\_topics) | The topics assigned to the repository |
| <a name="output_visibility"></a> [visibility](#output\_visibility) | The visibility of the repository |
| <a name="output_webhooks_count"></a> [webhooks\_count](#output\_webhooks\_count) | Number of webhooks created |
<!-- END_TF_DOCS -->
