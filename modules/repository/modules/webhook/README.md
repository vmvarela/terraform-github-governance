# GitHub Webhook Terraform sub-module

A Terraform module for GitHub webhooks GitHub.cks

## Usage

```hcl
module "webhook" {
  source         = "github.com/vmvarela/terraform-github-repository//modules/webhook"
  repository     = "my-repo"
  url            = "https://webhooks.my-company.com"
  content_type   = "json"
  events         = ["issues"]
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
| [github_repository_webhook.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_webhook) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_content_type"></a> [content\_type](#input\_content\_type) | The content type for the payload. Valid values are either `form` or `json`. | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | The repository of the webhook. | `string` | n/a | yes |
| <a name="input_url"></a> [url](#input\_url) | The URL of the webhook. | `string` | n/a | yes |
| <a name="input_events"></a> [events](#input\_events) | A list of events which should trigger the webhook. See a list of [available events](https://docs.github.com/es/webhooks/webhook-events-and-payloads). | `set(string)` | `[]` | no |
| <a name="input_insecure_ssl"></a> [insecure\_ssl](#input\_insecure\_ssl) | Insecure SSL boolean toggle. | `bool` | `false` | no |
| <a name="input_secret"></a> [secret](#input\_secret) | The shared secret for the webhook | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_webhook"></a> [webhook](#output\_webhook) | Created webhook |
<!-- END_TF_DOCS -->

## Authors

Module is maintained by [Victor M. Varela](https://github.com/vmvarela).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/vmvarela/terraform-github-repository/tree/master/LICENSE) for full details.
