# GitHub Repository Ruleset Terraform sub-module

A Terraform module for GitHub repository ruleset creation.


## Usage

```hcl
module "ruleset" {
  source      = "github.com/vmvarela/terraform-github-repository//modules/ruleset"
  repository  = "my-repo"
  name        = "my-rule"

}
```

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
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 6.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | 6.7.5 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [github_repository_ruleset.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | (String) The name of the ruleset. | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | The repository of the environment. | `string` | n/a | yes |
| <a name="input_bypass_integration"></a> [bypass\_integration](#input\_bypass\_integration) | List of GitHub App IDs that can bypass the rules in this ruleset. | `set(string)` | `[]` | no |
| <a name="input_bypass_mode"></a> [bypass\_mode](#input\_bypass\_mode) | When the specified actor can bypass the ruleset. `pull_request` means that an actor can only bypass rules on pull requests. Can be one of: `always`, `pull_request`. | `string` | `"always"` | no |
| <a name="input_bypass_organization_admin"></a> [bypass\_organization\_admin](#input\_bypass\_organization\_admin) | Organization Admin can bypass the rules in this ruleset. | `bool` | `null` | no |
| <a name="input_bypass_roles"></a> [bypass\_roles](#input\_bypass\_roles) | List of repository roles that can bypass the rules in this ruleset. | `set(string)` | `[]` | no |
| <a name="input_bypass_teams"></a> [bypass\_teams](#input\_bypass\_teams) | List of teams that can bypass the rules in this ruleset. | `set(string)` | `[]` | no |
| <a name="input_dismiss_pr_stale_reviews_on_push"></a> [dismiss\_pr\_stale\_reviews\_on\_push](#input\_dismiss\_pr\_stale\_reviews\_on\_push) | New, reviewable commits pushed will dismiss previous pull request review approvals. | `bool` | `null` | no |
| <a name="input_enforcement"></a> [enforcement](#input\_enforcement) | Possible values for Enforcement are `disabled`, `active`, `evaluate`. Note: `evaluate` is currently only supported for owners of type `organization`. | `string` | `"active"` | no |
| <a name="input_exclude"></a> [exclude](#input\_exclude) | Array of ref names or patterns to exclude. The condition will not pass if any of these patterns match. | `set(string)` | `[]` | no |
| <a name="input_forbidden_creation"></a> [forbidden\_creation](#input\_forbidden\_creation) | Only allow users with bypass permission to create matching refs. | `bool` | `null` | no |
| <a name="input_forbidden_deletion"></a> [forbidden\_deletion](#input\_forbidden\_deletion) | Only allow users with bypass permissions to delete matching refs. | `bool` | `null` | no |
| <a name="input_forbidden_fast_forward"></a> [forbidden\_fast\_forward](#input\_forbidden\_fast\_forward) | Prevent users with push access from force pushing to branches. | `bool` | `null` | no |
| <a name="input_forbidden_update"></a> [forbidden\_update](#input\_forbidden\_update) | Only allow users with bypass permission to update matching refs. | `bool` | `null` | no |
| <a name="input_include"></a> [include](#input\_include) | Array of ref names or patterns to include. One of these patterns must match for the condition to pass. Also accepts `~DEFAULT_BRANCH` to include the default branch or `~ALL` to include all branches. | `set(string)` | `[]` | no |
| <a name="input_regex_commit_author_email"></a> [regex\_commit\_author\_email](#input\_regex\_commit\_author\_email) | Pattern to match author email. | `string` | `null` | no |
| <a name="input_regex_commit_message"></a> [regex\_commit\_message](#input\_regex\_commit\_message) | Pattern to match commit message. | `string` | `null` | no |
| <a name="input_regex_committer_email"></a> [regex\_committer\_email](#input\_regex\_committer\_email) | Pattern to match committer email. | `string` | `null` | no |
| <a name="input_regex_target"></a> [regex\_target](#input\_regex\_target) | Pattern to match branch or tag. This rule only applies to repositories within an enterprise, it cannot be applied to repositories owned by individuals or regular organizations. | `string` | `null` | no |
| <a name="input_required_checks"></a> [required\_checks](#input\_required\_checks) | Choose which status checks must pass before branches can be merged into a branch that matches this rule. When enabled, commits must first be pushed to another branch, then merged or pushed directly to a branch that matches this rule after status checks have passed. | `set(string)` | `[]` | no |
| <a name="input_required_code_scanning"></a> [required\_code\_scanning](#input\_required\_code\_scanning) | The severity levels at which code scanning results that raise security alerts and alerts block a reference update. (key: tool, value are two severity values separated by ':'. First (security alerts) can be one of: `none`, `critical`, `high_or_higher`, `medium_or_higher`, `all` and second (alerts) can be one of: `none`, `critical`, `high_or_higher`, `medium_or_higher`, `all` `none`, `errors`, `errors_and_warnings`, `all`). | `map(string)` | `{}` | no |
| <a name="input_required_deployment_environments"></a> [required\_deployment\_environments](#input\_required\_deployment\_environments) | The environments that must be successfully deployed to before branches can be merged. | `set(string)` | `[]` | no |
| <a name="input_required_linear_history"></a> [required\_linear\_history](#input\_required\_linear\_history) | Prevent merge commits from being pushed to matching branches. | `bool` | `null` | no |
| <a name="input_required_pr_approving_review_count"></a> [required\_pr\_approving\_review\_count](#input\_required\_pr\_approving\_review\_count) | The number of approving reviews that are required before a pull request can be merged. | `number` | `null` | no |
| <a name="input_required_pr_code_owner_review"></a> [required\_pr\_code\_owner\_review](#input\_required\_pr\_code\_owner\_review) | Require an approving review in pull requests that modify files that have a designated code owner. | `bool` | `null` | no |
| <a name="input_required_pr_last_push_approval"></a> [required\_pr\_last\_push\_approval](#input\_required\_pr\_last\_push\_approval) | Whether the most recent reviewable push must be approved by someone other than the person who pushed it. | `bool` | `null` | no |
| <a name="input_required_pr_review_thread_resolution"></a> [required\_pr\_review\_thread\_resolution](#input\_required\_pr\_review\_thread\_resolution) | All conversations on code must be resolved before a pull request can be merged. | `bool` | `null` | no |
| <a name="input_required_signatures"></a> [required\_signatures](#input\_required\_signatures) | Commits pushed to matching branches must have verified signatures. | `bool` | `null` | no |
| <a name="input_target"></a> [target](#input\_target) | Possible values are `branch` and `tag`. | `string` | `"branch"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ruleset"></a> [ruleset](#output\_ruleset) | Created ruleset |
<!-- END_TF_DOCS -->

## Authors

Module is maintained by [Victor M. Varela](https://github.com/vmvarela).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/vmvarela/terraform-github-repository/tree/master/LICENSE) for full details.
