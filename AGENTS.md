# AGENTS.md — terraform-github-governance

Guidelines for agentic coding agents operating in this repository.

## Repository Overview

Terraform module for managing GitHub repository governance at scale. Provides a
preset system, standardized naming, branch protection, merge strategies, and
security settings via the GitHub provider (`integrations/github >= 6.8.0`,
Terraform `>= 1.7`).

Structure:
- Root module — orchestrates multiple repositories via `for_each`
- `modules/repository/` — core per-repository resource module
- `tests/` — root-level tests (`governance.tftest.hcl`, 22 tests)
- `modules/repository/tests/` — module-level tests (`repository.tftest.hcl`, 5 tests)
- `examples/simple/` and `examples/complete/` — usage examples

---

## Build / Lint / Test Commands

### Formatting

```bash
terraform fmt -recursive          # Format all .tf files
terraform fmt -check -recursive   # Validate formatting without modifying
```

### Validation

```bash
terraform validate                             # Root module
terraform -chdir=modules/repository validate   # Submodule
```

### Linting

```bash
tflint --only=terraform_deprecated_interpolation \
       --only=terraform_deprecated_index \
       --only=terraform_unused_declarations \
       --only=terraform_comment_syntax \
       --only=terraform_documented_outputs \
       --only=terraform_documented_variables \
       --only=terraform_typed_variables \
       --only=terraform_module_pinned_source \
       --only=terraform_naming_convention \
       --only=terraform_required_version \
       --only=terraform_required_providers \
       --only=terraform_standard_module_structure \
       --only=terraform_workspace_remote
```

### Tests

```bash
# Run all tests (root + module)
terraform test

# Run a single specific test file
terraform test -filter=tests/governance.tftest.hcl
terraform test -filter=modules/repository/tests/repository.tftest.hcl

# Run a single named test run block
terraform test -filter=tests/governance.tftest.hcl -run="<run_block_name>"

# Module tests
terraform -chdir=modules/repository test
```

### Docs

```bash
terraform-docs markdown table . > README.md        # Root
terraform-docs markdown table modules/repository/ > modules/repository/README.md
```

### Pre-commit (run before every commit)

```bash
pre-commit run --all-files          # Full suite (fmt, tflint, validate, docs, terraform test)
pre-commit run terraform_fmt        # Single hook
pre-commit run terraform-test       # Only the test hook
```

The `.pre-commit-config.yaml` runs these hooks automatically on `git commit`:
- `check-merge-conflict`, `end-of-file-fixer`, `trailing-whitespace`, `mixed-line-ending`
- `terraform_fmt`, `terraform_tflint`, `terraform_validate`, `terraform_docs`
- `conventional-pre-commit` (commit-msg stage)
- `terraform-test` (runs `terraform test` on any `.tf` change)

**Always run `pre-commit run --all-files` before committing.**

---

## Commit Style

This repo uses **Conventional Commits** (enforced by pre-commit):

```
feat: add ruleset bypass actor support
fix: correct team ID resolution order
docs: update module README with v2 breaking changes
refactor: simplify preset merge logic in locals.tf
test: add coverage for experimental preset override
chore: bump pre-commit-terraform to v1.103.0
```

---

## Terraform Code Style (HashiCorp conventions)

### File Organization

| File | Purpose |
|---|---|
| `terraform.tf` | `terraform {}` block with `required_version` and `required_providers` |
| `providers.tf` | Provider configuration blocks |
| `main.tf` | Primary resources and data sources |
| `variables.tf` | Input variables (alphabetical) |
| `outputs.tf` | Output values (alphabetical) |
| `locals.tf` | Local values |
| `data.tf` | Standalone data sources |

### Formatting

- **Two spaces** per nesting level — no tabs
- Align `=` signs for consecutive arguments in the same block
- Blank line between argument groups and before nested blocks
- `lifecycle` block always last inside a resource

### Naming Conventions

- **Lowercase with underscores** for all resource names, variables, outputs, locals
- **Descriptive nouns** that exclude the resource type (`web_api`, not `web_api_instance`)
- Use `main` when only one instance of a resource type exists
- **Singular** resource names (not plural)

```hcl
# Good
resource "github_repository" "main" {}
variable "repository_naming" {}
output "repository_urls" {}

# Bad
resource "github_repository" "GitHubRepo" {}
variable "repos" {}
```

### Variables

Every variable **must** have `type` and `description`. Add `validation` blocks for
constrained values. Mark secrets as `sensitive = true`.

```hcl
variable "organization" {
  description = "GitHub organization name"
  type        = string
}

variable "repository_naming" {
  description = "Optional prefix/suffix for repository names"
  type = object({
    prefix    = optional(string, "")
    separator = optional(string, "-")
  })
  default = {}

  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.repository_naming.prefix))
    error_message = "Prefix must be lowercase alphanumeric with hyphens only."
  }
}
```

### Outputs

Every output **must** have `description`. Mark sensitive outputs with `sensitive = true`.

```hcl
output "repository_urls" {
  description = "Map of repository name to HTML URL"
  value       = { for k, v in module.repository : k => v.url }
}
```

### Locals

Use locals to avoid repetition and to pre-compute complex expressions. Name them
descriptively; group related locals in the same `locals {}` block.

### Dynamic Resources

Prefer `for_each` over `count` for named resources; use `count` only for
conditional creation (`count = var.enable_x ? 1 : 0`).

### Version Constraints

```hcl
terraform {
  required_version = ">= 1.7"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.8.0"
    }
  }
}
```

Use `~>` for patch-level pinning in modules, `>=` for flexibility at the root.
Always commit `.terraform.lock.hcl`.

### Data Sources

Place conditional data sources in `data.tf`. Only fetch data when the corresponding
variable is empty (see `data.tf` pattern in this repo):

```hcl
data "github_organization_teams" "all" {
  count = length(local.referenced_teams) > 0 ? 1 : 0
}
```

---

## Error Handling and Validation

- Use `validation` blocks in variables for all constrained inputs
- Use `precondition` / `postcondition` in `lifecycle` for runtime guards
- Prefer explicit `null` defaults over empty strings for optional objects
- Avoid `try()` and `can()` except where schema uncertainty is unavoidable

---

## Security

- **Never** commit `.tfvars` files containing secrets
- **Never** hardcode tokens, passwords, or keys in `.tf` files
- Mark sensitive variables and outputs with `sensitive = true`
- Do not commit `terraform.tfstate`, `terraform.tfstate.backup`, or `.terraform/`
- Report vulnerabilities via GitHub Security Advisories (see SECURITY.md)

---

## Never Commit

```
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfplan
*.tfvars          # if they contain sensitive data
.terraform.tfvars
```

Always commit `.terraform.lock.hcl`.

---

## Skills in Use

Load the appropriate skill before starting each type of task:

| Task | Skill |
|---|---|
| Write or review any `.tf` file | `terraform-style-guide` (HashiCorp official conventions) |
| Author modules, write tests, set up CI/CD | `terraform-skill` |
| Create or edit `.tftest.hcl` test files | `terraform-test` |
| Write or improve `README.md`, module docs, `CHANGELOG`, `CONTRIBUTING.md` | `pragmatic-docs` |
| Plan features, manage Issues/Milestones/PRs, run sprints | `github-scrum` |
| Implement a non-trivial algorithm or complex `locals` expression | `methodical-programming` |

### When to invoke each skill

**`pragmatic-docs`** — Use whenever touching documentation: updating `README.md`
at root or under `modules/repository/`, writing release notes, or adding usage
examples. Produces concise, technically accurate docs in the style of Philip
Greenspun.

**`github-scrum`** — Use when planning work on GitHub: creating Issues for new
features or bugs, organising Milestones (sprints), writing PR descriptions, or
maintaining the Product Backlog. Adapted for solo/small-team workflows.

**`methodical-programming`** — Use when deriving correct `locals` expressions,
designing loop/for-expression logic, or implementing preset-merge algorithms.
Applies formal pre/post-condition reasoning to avoid subtle drift bugs.

**`hashicorp/agent-skills@terraform-style-guide`** — Load for every Terraform
code generation or review task to enforce HashiCorp's official style guide.

**`terraform-skill`** — Load when authoring new modules, choosing testing
strategies, or configuring CI/CD pipelines.

**`terraform-test`** — Load when creating or modifying `.tftest.hcl` files,
writing `run` blocks, mocking providers, or debugging test failures.
