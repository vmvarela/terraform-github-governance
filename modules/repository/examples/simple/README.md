# Simple Repository Example

This example demonstrates how to create a basic GitHub repository with minimal configuration using this Terraform module.

## Features

- Basic repository with public visibility
- Issue tracking and wiki enabled
- Repository topics for better discoverability
- Simple branch protection on the main branch

## Usage

To run this example you need to set the `GITHUB_TOKEN` environment variable and execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Run `terraform destroy` when you don't need these resources.

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

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_simple_repository"></a> [simple\_repository](#module\_simple\_repository) | ../.. | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
