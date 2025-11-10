# GitHub Environment Terraform sub-module

A Terraform module for GitHub environments.

> *NOTE*: If using a private repository: Ensure you're on GitHub Team or Enterprise Cloud plan.

## Usage

```hcl
module "environment" {
  source              = "github.com/vmvarela/terraform-github-repository//modules/environment"
  repository          = "my-repo"
  environment         = "staging"
  variables = {
    "MIVAR" = "MIVAL
  }
}
```

<!-- BEGIN_TF_DOCS -->
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
| [github_actions_environment_secret.encrypted](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_secret) | resource |
| [github_actions_environment_secret.plaintext](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_secret) | resource |
| [github_actions_environment_variable.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable) | resource |
| [github_repository_environment.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment) | resource |
| [github_repository_environment_deployment_policy.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment_deployment_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_can_admins_bypass"></a> [can\_admins\_bypass](#input\_can\_admins\_bypass) | Can repository admins bypass the environment protections. Defaults to `true`. | `bool` | `true` | no |
| <a name="input_custom_branch_policies"></a> [custom\_branch\_policies](#input\_custom\_branch\_policies) | Whether only branches that match the specified name patterns can deploy to this environment. | `set(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment. | `string` | n/a | yes |
| <a name="input_prevent_self_review"></a> [prevent\_self\_review](#input\_prevent\_self\_review) | Whether or not a user who created the job is prevented from approving their own job. Defaults to `false`. | `bool` | `false` | no |
| <a name="input_protected_branches"></a> [protected\_branches](#input\_protected\_branches) | Whether only branches with branch protection rules can deploy to this environment. | `bool` | `null` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | The repository of the environment. | `string` | n/a | yes |
| <a name="input_reviewers_teams"></a> [reviewers\_teams](#input\_reviewers\_teams) | Up to 6 IDs for teams who may review jobs that reference the environment. Reviewers must have at least read access to the repository. Only one of the required reviewers needs to approve the job for it to proceed. | `set(string)` | `[]` | no |
| <a name="input_reviewers_users"></a> [reviewers\_users](#input\_reviewers\_users) | Up to 6 IDs for users who may review jobs that reference the environment. Reviewers must have at least read access to the repository. Only one of the required reviewers needs to approve the job for it to proceed. | `set(string)` | `[]` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | (Optional) | `map(string)` | `{}` | no |
| <a name="input_secrets_encrypted"></a> [secrets\_encrypted](#input\_secrets\_encrypted) | (Optional) | `map(string)` | `{}` | no |
| <a name="input_variables"></a> [variables](#input\_variables) | (Optional) | `map(string)` | `{}` | no |
| <a name="input_wait_timer"></a> [wait\_timer](#input\_wait\_timer) | Amount of time to delay a job after the job is initially triggered. | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_can_admins_bypass"></a> [can\_admins\_bypass](#output\_can\_admins\_bypass) | Whether admins can bypass protection rules |
| <a name="output_custom_deployment_policies_count"></a> [custom\_deployment\_policies\_count](#output\_custom\_deployment\_policies\_count) | Number of custom deployment policies configured |
| <a name="output_deployment_branch_policy"></a> [deployment\_branch\_policy](#output\_deployment\_branch\_policy) | Deployment branch policy configuration |
| <a name="output_deployment_policies"></a> [deployment\_policies](#output\_deployment\_policies) | Created deployment policies |
| <a name="output_environment"></a> [environment](#output\_environment) | Complete environment object (use specific outputs for better terraform graph performance) |
| <a name="output_id"></a> [id](#output\_id) | Numeric ID of the environment |
| <a name="output_name"></a> [name](#output\_name) | Name of the environment |
| <a name="output_prevent_self_review"></a> [prevent\_self\_review](#output\_prevent\_self\_review) | Whether to prevent self-review |
| <a name="output_reviewers"></a> [reviewers](#output\_reviewers) | Required reviewers configuration |
| <a name="output_secrets_encrypted"></a> [secrets\_encrypted](#output\_secrets\_encrypted) | Created encrypted secrets |
| <a name="output_secrets_plaintext"></a> [secrets\_plaintext](#output\_secrets\_plaintext) | Created plaintext secrets |
| <a name="output_secrets_summary"></a> [secrets\_summary](#output\_secrets\_summary) | Summary of secrets configured in this environment |
| <a name="output_variables"></a> [variables](#output\_variables) | Created variables |
| <a name="output_variables_count"></a> [variables\_count](#output\_variables\_count) | Number of variables configured in this environment |
| <a name="output_wait_timer"></a> [wait\_timer](#output\_wait\_timer) | Wait timer in minutes before deployment |
<!-- END_TF_DOCS -->

## Authors

Module is maintained by [Victor M. Varela](https://github.com/vmvarela).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/vmvarela/terraform-github-repository/tree/master/LICENSE) for full details.
