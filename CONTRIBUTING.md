# Contributing to terraform-github-governance

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Table of Contents

- [Development Setup](#development-setup)
- [Running Tests](#running-tests)
- [Code Style](#code-style)
- [Pull Request Process](#pull-request-process)
- [Commit Message Format](#commit-message-format)
- [Adding New Features](#adding-new-features)

## Development Setup

### Prerequisites

- Terraform >= 1.6
- Pre-commit (optional but recommended)
- GitHub Personal Access Token with required scopes:
  - `admin:org` - Organization management
  - `repo` - Repository management
  - `workflow` - Actions and runner management

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/vmvarela/terraform-github-governance.git
   cd terraform-github-governance
   ```

2. **Install pre-commit hooks** (recommended)
   ```bash
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

3. **Set up environment**
   ```bash
   export TF_VAR_github_token="your_token_here"
   ```

4. **Initialize Terraform**
   ```bash
   terraform init
   ```

## Running Tests

### All Tests
```bash
terraform test
```

or using Makefile:
```bash
make test
```

### Specific Test File
```bash
terraform test -filter=tests/locals.tftest.hcl
```

### Verbose Output
```bash
terraform test -verbose
```

### Test Coverage
The project maintains 24+ unit tests covering:
- Variable validations
- Local value logic
- Mode-specific behavior (organization vs project)
- Security validations

**Goal:** Maintain 100% pass rate on all tests.

## Code Style

### Terraform

- Use `terraform fmt` before committing (enforced by pre-commit)
- Follow [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- Use meaningful variable and resource names
- Add descriptions to all variables and outputs
- Use validation blocks for input validation

### Code Quality Checks

Before submitting PR:

```bash
# Format code
make fmt

# Validate configuration
make validate

# Run all tests
make test
```

### Pre-commit Hooks

The project uses pre-commit hooks to enforce:
- `terraform fmt` - Code formatting
- `terraform validate` - Configuration validation
- `terraform_tflint` - Linting and best practices
- `terraform test` - Unit tests
- `conventional-pre-commit` - Commit message format

## Pull Request Process

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

3. **Make your changes**
   - Follow code style guidelines
   - Add tests for new features
   - Update documentation

4. **Run tests and validation**
   ```bash
   make validate
   make test
   ```

5. **Commit your changes**
   - Use conventional commit format (see below)
   - Keep commits atomic and focused

6. **Push and create PR**
   ```bash
   git push origin feature/my-feature
   ```

7. **PR Requirements**
   - All CI checks must pass
   - Code review approval required
   - Tests must pass (24/24)
   - Documentation updated if needed

## Commit Message Format

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automatic changelog generation and semantic versioning.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(runner-groups): add workflow restrictions` |
| `fix` | Bug fix | `fix(validations): correct webhook secret validation` |
| `docs` | Documentation only | `docs(readme): add project mode examples` |
| `test` | Test additions/changes | `test(locals): add test for alias handling` |
| `refactor` | Code refactoring | `refactor(main): extract mode logic to locals` |
| `chore` | Maintenance tasks | `chore(deps): update github provider to 6.1` |
| `ci` | CI/CD changes | `ci(github): add automated release workflow` |
| `perf` | Performance improvements | `perf(data): optimize repository lookup` |

### Scopes

Common scopes in this project:
- `runner-groups` - Runner group management
- `repositories` - Repository configuration
- `validations` - Input validations
- `tests` - Test files
- `docs` - Documentation
- `examples` - Example configurations

### Examples

```bash
# Feature addition
feat(secrets): add support for encrypted secrets validation

# Bug fix
fix(mode): correct repository scoping in project mode

# Documentation
docs(readme): add terraform-docs generated sections

# Breaking change
feat(api)!: change settings variable structure

BREAKING CHANGE: settings variable now requires billing_email
```

### Breaking Changes

For breaking changes:
1. Add `!` after type: `feat!:` or `fix!:`
2. Include `BREAKING CHANGE:` in footer with migration guide

## Adding New Features

### Checklist

When adding new features, ensure:

- [ ] Variable added to `variables.tf` with description
- [ ] Variable validation added if applicable
- [ ] Check block added for runtime validation (if needed)
- [ ] Unit tests added in `tests/`
- [ ] Documentation updated in README.md
- [ ] Example added or updated
- [ ] Outputs documented if added
- [ ] Pre-commit hooks pass
- [ ] All tests pass

### Variable Guidelines

```terraform
variable "my_feature" {
  description = <<-EOT
    Clear description of the variable purpose.
    
    Example:
    {
      key = "value"
    }
  EOT
  type = object({
    # Use strongly typed objects
    key = string
  })
  default = null  # Provide sensible defaults
  
  validation {
    condition     = var.my_feature != null ? length(var.my_feature) > 0 : true
    error_message = "Clear, actionable error message."
  }
}
```

### Test Guidelines

Add tests in `tests/` directory:

```hcl
run "test_my_feature" {
  command = plan
  
  variables {
    mode = "organization"
    name = "test-org"
    settings = {
      billing_email = "test@example.com"
    }
    my_feature = {
      key = "value"
    }
  }
  
  assert {
    condition     = length(var.my_feature) == 1
    error_message = "Feature should be configured"
  }
}
```

## Documentation

### Updating README

The README uses `terraform-docs` for automatic generation:

1. Update inline comments in `main.tf`, `variables.tf`, `outputs.tf`
2. Run terraform-docs:
   ```bash
   terraform-docs markdown table --config .terraform-docs.yml .
   ```
3. Or let pre-commit handle it automatically

### Adding Examples

Place examples in `examples/`:
```
examples/
  my-example/
    main.tf
    variables.tf
    outputs.tf
    README.md
    terraform.tfvars.example
```

## Release Process

Releases are automated via semantic-release:

1. **Commit to main** with conventional commit messages
2. **CI runs** tests and validation
3. **Semantic-release** determines version bump based on commits:
   - `fix:` → Patch version (1.0.X)
   - `feat:` → Minor version (1.X.0)
   - `feat!:` or `BREAKING CHANGE:` → Major version (X.0.0)
4. **CHANGELOG.md** generated automatically
5. **GitHub release** created with notes

## Getting Help

- 📖 Read the [README.md](./README.md)
- 🧪 Check [tests/](./tests/) for examples
- 📝 Review [ANALYSIS.md](./ANALYSIS.md) for architecture details
- 💬 Open an issue for questions

## Code of Conduct

Be respectful, inclusive, and constructive. We're all here to learn and improve.

---

**Thank you for contributing!** 🎉
