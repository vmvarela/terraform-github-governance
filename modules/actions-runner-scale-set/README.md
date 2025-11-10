# GitHub Actions Runner Scale Set on Kubernetes

Terraform module that deploys self-hosted GitHub Actions runners on Kubernetes using the official [Actions Runner Controller (ARC)](https://github.com/actions/actions-runner-controller).

This module automates the deployment of:
- **ARC Controller**: Manages the lifecycle of runner scale sets
- **Runner Scale Sets**: Auto-scaling GitHub Actions runners
- **Runner Groups**: Organized runner access control (optional)
- **Authentication**: Support for both GitHub Apps and Personal Access Tokens

## Features

- ✅ Multiple scale sets with independent configurations
- ✅ Auto-scaling runners (min/max configuration)
- ✅ GitHub App or PAT authentication
- ✅ Private container registry support
- ✅ Runner group management with repository and workflow restrictions
- ✅ Flexible runner image configuration
- ✅ Container mode support (Docker-in-Docker or Kubernetes)
- ✅ Automatic namespace creation

## Usage

### Basic Example

```hcl
module "github_runners" {
  source  = "path/to/module"

  github_org   = "my-organization"
  github_token = var.github_token
}
```

### Complete Example with Multiple Scale Sets

```hcl
module "github_runners" {
  source = "path/to/module"

  github_org   = "my-organization"
  github_token = var.github_token

  controller = {
    name             = "arc-controller"
    namespace        = "arc-system"
    create_namespace = true
    version          = "0.13.0"
  }

  scale_sets = {
    "default-runners" = {
      namespace           = "arc-runners-default"
      create_namespace    = true
      min_runners         = 1
      max_runners         = 10
      runner_image        = "ghcr.io/actions/actions-runner:latest"
      container_mode      = "dind"
      visibility          = "all"
      create_runner_group = true
    }

    "production-runners" = {
      namespace           = "arc-runners-prod"
      create_namespace    = true
      min_runners         = 2
      max_runners         = 20
      runner_group        = "production"
      visibility          = "selected"
      repositories        = ["repo1", "repo2"]
      create_runner_group = true
    }

    "ci-runners" = {
      namespace           = "arc-runners-ci"
      create_namespace    = true
      min_runners         = 3
      max_runners         = 15
      runner_group        = "ci"
      visibility          = "selected"
      workflows           = [".github/workflows/ci.yml"]
      create_runner_group = true
    }
  }
}
```

### GitHub App Authentication

```hcl
module "github_runners" {
  source = "path/to/module"

  github_org                 = "my-organization"
  github_app_id              = 123456
  github_app_installation_id = 789012
  github_app_private_key     = file("${path.module}/github-app-key.pem")
}
```

### Private Container Registry

```hcl
module "github_runners" {
  source = "path/to/module"

  github_org   = "my-organization"
  github_token = var.github_token

  private_registry          = "registry.example.com"
  private_registry_username = var.registry_username
  private_registry_password = var.registry_password

  scale_sets = {
    "custom-image-runners" = {
      runner_image = "registry.example.com/custom/runner:latest"
    }
  }
}
```

## Authentication Methods

This module supports two authentication methods with GitHub:

### Personal Access Token (PAT)

```hcl
module "github_runners" {
  source       = "path/to/module"
  github_org   = "my-organization"
  github_token = var.github_token  # Classic PAT with admin:org scope
}
```

**Required Scopes:**
- `admin:org` (for runner group management)
- `repo` (if managing repository runners)

### GitHub App

```hcl
module "github_runners" {
  source                     = "path/to/module"
  github_org                 = "my-organization"
  github_app_id              = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_private_key     = file("github-app-key.pem")
}
```

**Required Permissions:**
- Repository permissions: `Actions: Read & Write`, `Administration: Read & Write`
- Organization permissions: `Self-hosted runners: Read & Write`

## Scale Set Configuration

### Container Modes

- **`dind`** (Docker-in-Docker): Runs Docker daemon inside the runner container
- **`kubernetes`**: Uses Kubernetes-native container execution
- **`null`**: No container mode (bare runner)

### Visibility Options

- **`all`**: Runners available to all repositories in the organization
- **`selected`**: Runners limited to specific repositories
- **`private`**: Runners available only to private repositories

### Runner Groups

Runner groups organize runners and control access:

```hcl
scale_sets = {
  "backend-runners" = {
    runner_group        = "backend-team"
    create_runner_group = true
    visibility          = "selected"
    repositories        = ["api", "database", "worker"]
    workflows           = [".github/workflows/deploy.yml"]
  }
}
```

## Testing

This module includes comprehensive Terraform native tests using mock providers:

```bash
terraform test
```

Tests cover:
- Controller creation
- Multiple scale sets
- GitHub App authentication
- Private registry configuration
- Runner groups
- Variable validations
- Container modes
- Resource dependencies

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | 6.7.5 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.1.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [github_actions_runner_group.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_runner_group) | resource |
| [helm_release.controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.scale_set](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.controller](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.scale_set](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.github_creds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.private_registry_creds](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [github_repositories.all](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repositories) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_controller"></a> [controller](#input\_controller) | Controller configuration | <pre>object({<br/>    name             = optional(string, "arc")<br/>    namespace        = optional(string, "arc-systems")<br/>    create_namespace = optional(bool, true)<br/>    version          = optional(string, "0.13.0")<br/>  })</pre> | <pre>{<br/>  "create_namespace": true,<br/>  "name": "arc",<br/>  "namespace": "arc-systems",<br/>  "version": "0.13.0"<br/>}</pre> | no |
| <a name="input_github_app_id"></a> [github\_app\_id](#input\_github\_app\_id) | GitHub App ID | `number` | `null` | no |
| <a name="input_github_app_installation_id"></a> [github\_app\_installation\_id](#input\_github\_app\_installation\_id) | GitHub App Installation ID | `number` | `null` | no |
| <a name="input_github_app_private_key"></a> [github\_app\_private\_key](#input\_github\_app\_private\_key) | GitHub App private key (PEM format) | `string` | `null` | no |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | GitHub organization name | `string` | n/a | yes |
| <a name="input_github_repositories"></a> [github\_repositories](#input\_github\_repositories) | All repositories in the organization. If not provided, they will be fetched by the module. | `any` | `null` | no |
| <a name="input_github_token"></a> [github\_token](#input\_github\_token) | GitHub Token | `string` | `null` | no |
| <a name="input_private_registry"></a> [private\_registry](#input\_private\_registry) | Private container registry URL | `string` | `null` | no |
| <a name="input_private_registry_password"></a> [private\_registry\_password](#input\_private\_registry\_password) | Private container registry password | `string` | `null` | no |
| <a name="input_private_registry_username"></a> [private\_registry\_username](#input\_private\_registry\_username) | Private container registry username | `string` | `null` | no |
| <a name="input_scale_sets"></a> [scale\_sets](#input\_scale\_sets) | Scale sets configuration (map) | <pre>map(object({<br/>    runner_group        = optional(string, null)<br/>    create_runner_group = optional(bool, true)<br/>    namespace           = optional(string, "arc-runners")<br/>    create_namespace    = optional(bool, true)<br/>    version             = optional(string, "0.13.0")<br/>    min_runners         = optional(number, 1)<br/>    max_runners         = optional(number, 5)<br/>    runner_image        = optional(string, "ghcr.io/actions/actions-runner:latest")<br/>    pull_always         = optional(bool, true)<br/>    container_mode      = optional(string, "dind")<br/>    visibility          = optional(string, "all")<br/>    workflows           = optional(list(string), null)<br/>    repositories        = optional(list(string), null)<br/>  }))</pre> | <pre>{<br/>  "arc-runner-set": {<br/>    "container_mode": "dind",<br/>    "create_namespace": true,<br/>    "create_runner_group": true,<br/>    "max_runners": 5,<br/>    "min_runners": 1,<br/>    "namespace": "arc-runners",<br/>    "pull_always": true,<br/>    "repositories": null,<br/>    "runner_group": null,<br/>    "runner_image": "ghcr.io/actions/actions-runner:latest",<br/>    "version": "0.13.0",<br/>    "visibility": "all",<br/>    "workflows": null<br/>  }<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_controller"></a> [controller](#output\_controller) | The Helm release of the controller. |
| <a name="output_controller_namespace"></a> [controller\_namespace](#output\_controller\_namespace) | The namespace where the controller is deployed. |
| <a name="output_github_secret_names"></a> [github\_secret\_names](#output\_github\_secret\_names) | Map of scale set names to their GitHub credentials secret names. |
| <a name="output_has_private_registry"></a> [has\_private\_registry](#output\_has\_private\_registry) | Whether private registry is configured. |
| <a name="output_namespace_names"></a> [namespace\_names](#output\_namespace\_names) | List of namespace names created for scale sets. |
| <a name="output_namespaces"></a> [namespaces](#output\_namespaces) | Map of namespaces created for scale sets. |
| <a name="output_private_registry"></a> [private\_registry](#output\_private\_registry) | The private registry URL if configured. |
| <a name="output_runner_group_ids"></a> [runner\_group\_ids](#output\_runner\_group\_ids) | Map of runner group names to their IDs. |
| <a name="output_runner_group_names"></a> [runner\_group\_names](#output\_runner\_group\_names) | List of runner group names that were created. |
| <a name="output_runner_groups"></a> [runner\_groups](#output\_runner\_groups) | Map of runner group names to their details. |
| <a name="output_scale_set_count"></a> [scale\_set\_count](#output\_scale\_set\_count) | Number of scale sets created. |
| <a name="output_scale_set_names"></a> [scale\_set\_names](#output\_scale\_set\_names) | List of scale set names that were created. |
| <a name="output_scale_sets"></a> [scale\_sets](#output\_scale\_sets) | Map of scale set names to their configuration details. |
| <a name="output_summary"></a> [summary](#output\_summary) | Summary of the scale sets deployment. |
<!-- END_TF_DOCS -->

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Authors

Created and maintained by [Your Name/Organization]
