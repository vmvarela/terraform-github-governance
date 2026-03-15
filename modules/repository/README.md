# GitHub Repository Module

The repository submodule used by the governance module. Can also be used directly when you need a single repository or don't want the preset system.

**For managing many repositories with shared presets**, use the parent [governance module](../../) instead.

## Usage

### Basic repository

```hcl
module "repository" {
  source = "./modules/repository"

  name         = "my-service"
  organization = "my-org"
  description  = "My service"
  visibility   = "private"
  topics       = ["service", "backend"]
}
```

### With branch protection

```hcl
module "repository" {
  source = "./modules/repository"

  name         = "api-service"
  organization = "my-org"

  protected_branches      = ["main", "release/*"]
  allow_bypass            = ["org-admin", "team:sre"]
  required_approvals      = 2
  required_checks         = ["ci", "security-scan"]
  prevent_force_push      = true
  prevent_branch_deletion = true
}
```

When `required_approvals > 0`, code owner review and thread resolution are enforced automatically.

Valid bypass formats: `org-admin` · `role:maintain|write|admin` · `team:<slug>` · `app:<slug>`

### With permissions

```hcl
permissions = {
  "team:engineers" = "push"
  "team:external"  = "pull"
  "user:alice"     = "admin"
}
```

Built-in roles: `pull`, `triage`, `push`, `maintain`, `admin`. Set `allowed_roles = []` to disable validation and use custom organization roles.

GitHub automatically elevates org owners to `admin` regardless of what you set — don't list them in `permissions` unless you're documenting intent.

### With environments

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

Reviewers must have at least `push` permission. The module auto-elevates any reviewer below that threshold. To grant a higher role, set it explicitly in `permissions`.

### With deploy keys and webhooks

```hcl
deploy_keys = {
  "CI/CD Key" = {
    key       = "ssh-rsa AAAA..."
    read_only = false
  }
}

webhooks = {
  ci = {
    url    = "https://ci.example.com/webhook"
    events = ["push", "pull_request"]
    secret = "webhook-secret"
  }
}
```

## ID resolution

This module does not perform any data source lookups. All team, user, and app IDs must be passed via `github_team_ids`, `github_user_ids`, and `github_app_ids`. The parent governance module handles this automatically; for direct usage, fetch IDs yourself:

```hcl
data "github_team" "sre" { slug = "sre" }

module "repository" {
  source = "./modules/repository"

  name            = "my-repo"
  organization    = "my-org"
  allow_bypass    = ["team:sre"]
  github_team_ids = { sre = data.github_team.sre.id }
  github_user_ids = {}
  github_app_ids  = {}
}
```

## Testing

```bash
terraform -chdir=modules/repository test
```

## Examples

- [`examples/simple/`](./examples/simple/) — minimal configuration
- [`examples/complete/`](./examples/complete/) — branch protection, permissions, environments

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

No modules.

## Resources

| Name | Type |
|------|------|
| [github_actions_environment_secret.env_secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_secret) | resource |
| [github_actions_environment_variable.env_var](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable) | resource |
| [github_actions_secret.repo_secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_variable.repo_var](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_branch_default.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_default) | resource |
| [github_repository.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) | resource |
| [github_repository_collaborators.all](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_collaborators) | resource |
| [github_repository_custom_property.property](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_custom_property) | resource |
| [github_repository_deploy_key.deploy_key](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_deploy_key) | resource |
| [github_repository_environment.env](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment) | resource |
| [github_repository_ruleset.ruleset](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |
| [github_repository_webhook.webhook](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_webhook) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_auto_merge"></a> [allow\_auto\_merge](#input\_allow\_auto\_merge) | Set to true to allow auto-merging pull requests on the repository. | `bool` | `false` | no |
| <a name="input_allow_bypass"></a> [allow\_bypass](#input\_allow\_bypass) | Actors allowed to bypass protections: 'org-admin', 'role:maintain\|write\|admin', 'team:slug', 'app:slug'. | `list(string)` | `[]` | no |
| <a name="input_allow_merge_commit"></a> [allow\_merge\_commit](#input\_allow\_merge\_commit) | Set to false to disable merge commits on the repository. | `bool` | `true` | no |
| <a name="input_allow_rebase_merge"></a> [allow\_rebase\_merge](#input\_allow\_rebase\_merge) | Set to false to disable rebase merges on the repository. | `bool` | `true` | no |
| <a name="input_allow_squash_merge"></a> [allow\_squash\_merge](#input\_allow\_squash\_merge) | Set to false to disable squash merges on the repository. | `bool` | `true` | no |
| <a name="input_allow_update_branch"></a> [allow\_update\_branch](#input\_allow\_update\_branch) | Set to true to always suggest updating pull request branches. | `bool` | `false` | no |
| <a name="input_allowed_roles"></a> [allowed\_roles](#input\_allowed\_roles) | List of allowed repository roles. Empty list disables validation. Defaults to GitHub built-in roles. | `list(string)` | <pre>[<br/>  "pull",<br/>  "triage",<br/>  "push",<br/>  "maintain",<br/>  "admin"<br/>]</pre> | no |
| <a name="input_archived"></a> [archived](#input\_archived) | Specifies if the repository should be archived. NOTE: currently the API does not support unarchiving. | `bool` | `false` | no |
| <a name="input_default_branch"></a> [default\_branch](#input\_default\_branch) | The name of the main branch (e.g., 'main'). | `string` | `"main"` | no |
| <a name="input_delete_branch_on_merge"></a> [delete\_branch\_on\_merge](#input\_delete\_branch\_on\_merge) | Automatically delete head branch after a pull request is merged. | `bool` | `false` | no |
| <a name="input_deploy_keys"></a> [deploy\_keys](#input\_deploy\_keys) | Map of deploy keys to add. The map key is the title of the deploy key. | <pre>map(object({<br/>    key       = string # The SSH public key<br/>    read_only = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_description"></a> [description](#input\_description) | A short, friendly description of the repository's purpose. | `string` | `null` | no |
| <a name="input_environments"></a> [environments](#input\_environments) | Defines CI/CD environments (e.g., 'staging', 'production') with optional required\_approvers (teams/users), secrets and variables. Empty or omitted required\_approvers disables reviewer protection. | <pre>map(object({<br/>    required_approvers = optional(list(string), []) # e.g., ["user:login", "team:slug"]<br/>    secrets            = optional(map(string), {})<br/>    variables          = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_github_app_ids"></a> [github\_app\_ids](#input\_github\_app\_ids) | Map of app slug -> app installation ID. Required for branch bypass app actors. Must be provided by parent governance module. | `map(number)` | `{}` | no |
| <a name="input_github_team_ids"></a> [github\_team\_ids](#input\_github\_team\_ids) | Map of team slug -> team ID. Required for branch bypass actors and environment reviewers. Must be provided by parent governance module. | `map(number)` | `{}` | no |
| <a name="input_github_user_ids"></a> [github\_user\_ids](#input\_github\_user\_ids) | Map of user login -> user ID. Required for environment reviewers. Must be provided by parent governance module. | `map(number)` | `{}` | no |
| <a name="input_has_discussions"></a> [has\_discussions](#input\_has\_discussions) | Set to true to enable GitHub Discussions on the repository. | `bool` | `false` | no |
| <a name="input_has_issues"></a> [has\_issues](#input\_has\_issues) | Set to true to enable the GitHub Issues features on the repository. | `bool` | `true` | no |
| <a name="input_has_projects"></a> [has\_projects](#input\_has\_projects) | Set to true to enable the GitHub Projects features on the repository. | `bool` | `true` | no |
| <a name="input_has_wiki"></a> [has\_wiki](#input\_has\_wiki) | Set to true to enable the GitHub Wiki features on the repository. | `bool` | `true` | no |
| <a name="input_homepage_url"></a> [homepage\_url](#input\_homepage\_url) | URL of a page describing the project. | `string` | `null` | no |
| <a name="input_is_template"></a> [is\_template](#input\_is\_template) | Mark this repository as a template repository. | `bool` | `false` | no |
| <a name="input_merge_commit_message"></a> [merge\_commit\_message](#input\_merge\_commit\_message) | Default merge commit message. Can be 'PR\_BODY', 'PR\_TITLE', or 'BLANK'. Applicable only if allow\_merge\_commit is true. | `string` | `null` | no |
| <a name="input_merge_commit_title"></a> [merge\_commit\_title](#input\_merge\_commit\_title) | Default merge commit title. Can be 'PR\_TITLE' or 'MERGE\_MESSAGE'. Applicable only if allow\_merge\_commit is true. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the repository. Must be unique within its workspace (organization, group, or project). | `string` | n/a | yes |
| <a name="input_organization"></a> [organization](#input\_organization) | GitHub organization name where the repository will be created. | `string` | n/a | yes |
| <a name="input_permissions"></a> [permissions](#input\_permissions) | Map of permission grants. Key is the entity ('user:name' or 'team:slug'), Value is the provider-specific role name (e.g., 'write', 'admin', 'my-custom-role'). | `map(string)` | `{}` | no |
| <a name="input_prevent_branch_deletion"></a> [prevent\_branch\_deletion](#input\_prevent\_branch\_deletion) | Prevent deletion of protected branches. | `bool` | `true` | no |
| <a name="input_prevent_force_push"></a> [prevent\_force\_push](#input\_prevent\_force\_push) | Prevent force-pushes (non-fast-forward). | `bool` | `true` | no |
| <a name="input_properties"></a> [properties](#input\_properties) | Generic key-value metadata properties. | `map(string)` | `{}` | no |
| <a name="input_protected_branches"></a> [protected\_branches](#input\_protected\_branches) | Branches to protect. Empty list disables the ruleset. Patterns like 'main', 'release/*'. | `list(string)` | `[]` | no |
| <a name="input_repository_secrets"></a> [repository\_secrets](#input\_repository\_secrets) | Map of secrets at the REPOSITORY level (global). Keys are secret names, values are secret values. | `map(string)` | `{}` | no |
| <a name="input_repository_variables"></a> [repository\_variables](#input\_repository\_variables) | Map of variables at the REPOSITORY level (global). | `map(string)` | `{}` | no |
| <a name="input_required_approvals"></a> [required\_approvals](#input\_required\_approvals) | Number of required PR approvals. 0 disables PR requirement. | `number` | `1` | no |
| <a name="input_required_checks"></a> [required\_checks](#input\_required\_checks) | List of required status check contexts. Strict policy is always enforced. | `list(string)` | `[]` | no |
| <a name="input_squash_merge_commit_message"></a> [squash\_merge\_commit\_message](#input\_squash\_merge\_commit\_message) | Default squash merge commit message. Can be 'PR\_BODY', 'COMMIT\_MESSAGES', or 'BLANK'. Applicable only if allow\_squash\_merge is true. | `string` | `null` | no |
| <a name="input_squash_merge_commit_title"></a> [squash\_merge\_commit\_title](#input\_squash\_merge\_commit\_title) | Default squash merge commit title. Can be 'PR\_TITLE' or 'COMMIT\_OR\_PR\_TITLE'. Applicable only if allow\_squash\_merge is true. | `string` | `null` | no |
| <a name="input_template"></a> [template](#input\_template) | Create this repository from a template repository. Use 'owner/repo' format. | <pre>object({<br/>    repository           = string # "owner/repo" format<br/>    include_all_branches = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_topics"></a> [topics](#input\_topics) | A list of GitHub topics to classify the repository. | `list(string)` | `[]` | no |
| <a name="input_visibility"></a> [visibility](#input\_visibility) | Visibility of the repository. Valid values: 'public', 'private', or 'internal'. | `string` | `"private"` | no |
| <a name="input_vulnerability_alerts"></a> [vulnerability\_alerts](#input\_vulnerability\_alerts) | Set to true to enable security alerts for vulnerable dependencies. | `bool` | `true` | no |
| <a name="input_web_commit_signoff_required"></a> [web\_commit\_signoff\_required](#input\_web\_commit\_signoff\_required) | Require contributors to sign off on web-based commits. | `bool` | `false` | no |
| <a name="input_webhooks"></a> [webhooks](#input\_webhooks) | Map of webhooks to configure. Key is the webhook name. | <pre>map(object({<br/>    url    = string<br/>    events = list(string) # Generic events: 'push', 'pull_request', 'issue'<br/>    secret = optional(string, null)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_archived"></a> [archived](#output\_archived) | Whether the repository is archived |
| <a name="output_default_branch"></a> [default\_branch](#output\_default\_branch) | The name of the default branch of the repository |
| <a name="output_delete_branch_on_merge"></a> [delete\_branch\_on\_merge](#output\_delete\_branch\_on\_merge) | Whether head branches are automatically deleted after merge |
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
| <a name="output_repository_secrets_count"></a> [repository\_secrets\_count](#output\_repository\_secrets\_count) | Number of repository secrets |
| <a name="output_repository_variables_count"></a> [repository\_variables\_count](#output\_repository\_variables\_count) | Number of repository variables |
| <a name="output_ssh_clone_url"></a> [ssh\_clone\_url](#output\_ssh\_clone\_url) | URL that can be provided to git clone to clone the repository via SSH |
| <a name="output_topics"></a> [topics](#output\_topics) | The topics assigned to the repository |
| <a name="output_visibility"></a> [visibility](#output\_visibility) | The visibility of the repository |
| <a name="output_webhooks_count"></a> [webhooks\_count](#output\_webhooks\_count) | Number of webhooks created |
<!-- END_TF_DOCS -->
