# GitHub File Terraform sub-module

A Terraform module for GitHub file creation.

## Usage

```hcl
module "file" {
  source              = "github.com/vmvarela/terraform-github-repository//modules/file"
  repository          = "my-repo"
  branch              = "main"
  file                = ".gitignore"
  content             = "**/*.tfstate"
  commit_message      = "Managed by Terraform"
  commit_author       = "Terraform User"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
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
| [github_repository_file.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autocreate_branch"></a> [autocreate\_branch](#input\_autocreate\_branch) | Automatically create the branch if it could not be found. Defaults to `false`. Subsequent reads if the branch is deleted will occur from `autocreate_branch_source_branch`. | `bool` | `null` | no |
| <a name="input_autocreate_branch_source_branch"></a> [autocreate\_branch\_source\_branch](#input\_autocreate\_branch\_source\_branch) | The branch name to start from, if `autocreate_branch` is set. Defaults to `main`. | `string` | `null` | no |
| <a name="input_autocreate_branch_source_sha"></a> [autocreate\_branch\_source\_sha](#input\_autocreate\_branch\_source\_sha) | The commit hash to start from, if `autocreate_branch` is set. Defaults to the tip of `autocreate_branch_source_branch`. If provided, `autocreate_branch_source_branch` is ignored. | `string` | `null` | no |
| <a name="input_branch"></a> [branch](#input\_branch) | Git branch (defaults to the repository's default branch). The branch must already exist, it will only be created automatically if `autocreate_branch` is set `true`. | `string` | `null` | no |
| <a name="input_commit_author"></a> [commit\_author](#input\_commit\_author) | Committer author name to use. NOTE: GitHub app users may omit author and email information so GitHub can verify commits as the GitHub App. This maybe useful when a branch protection rule requires signed commits. | `string` | `null` | no |
| <a name="input_commit_email"></a> [commit\_email](#input\_commit\_email) | Committer email address to use. NOTE: GitHub app users may omit author and email information so GitHub can verify commits as the GitHub App. This may be useful when a branch protection rule requires signed commits. | `string` | `null` | no |
| <a name="input_commit_message"></a> [commit\_message](#input\_commit\_message) | The commit message when creating, updating or deleting the managed file. | `string` | `null` | no |
| <a name="input_content"></a> [content](#input\_content) | The file content. | `string` | `null` | no |
| <a name="input_file"></a> [file](#input\_file) | The path of the file to manage. | `string` | n/a | yes |
| <a name="input_from_file"></a> [from\_file](#input\_from\_file) | File to load content from | `string` | `null` | no |
| <a name="input_overwrite_on_create"></a> [overwrite\_on\_create](#input\_overwrite\_on\_create) | Enable overwriting existing files. If set to `true` it will overwrite an existing file with the same name. If set to `false` it will fail if there is an existing file with the same name | `bool` | `null` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | The repository to create the file in. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_branch"></a> [branch](#output\_branch) | Branch where the file was created |
| <a name="output_commit_author"></a> [commit\_author](#output\_commit\_author) | Author of the commit |
| <a name="output_commit_email"></a> [commit\_email](#output\_commit\_email) | Email of the commit author |
| <a name="output_commit_message"></a> [commit\_message](#output\_commit\_message) | Commit message used when creating/updating the file |
| <a name="output_commit_sha"></a> [commit\_sha](#output\_commit\_sha) | SHA of the commit that created/updated the file |
| <a name="output_file"></a> [file](#output\_file) | Complete file object (use specific outputs for better terraform graph performance) |
| <a name="output_id"></a> [id](#output\_id) | ID of the file resource |
| <a name="output_path"></a> [path](#output\_path) | Path of the file in the repository |
<!-- END_TF_DOCS -->

## Authors

Module is maintained by [Victor M. Varela](https://github.com/vmvarela).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/vmvarela/terraform-github-repository/tree/master/LICENSE) for full details.
