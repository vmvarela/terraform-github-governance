# Tests for Terraform GitHub Repository Module

This directory contains native HCL tests for the terraform-github-repository module using mock providers.

## Test Structure

```
tests/
├── README.md                    # This file
├── repository.tftest.hcl       # Main module tests (20 tests)
├── environment.tftest.hcl      # Environment submodule tests (10 tests)
├── ruleset.tftest.hcl          # Ruleset submodule tests (18 tests)
├── webhook.tftest.hcl          # Webhook submodule tests (12 tests)
├── file.tftest.hcl             # File submodule tests (15 tests)
└── integration.tftest.hcl      # Integration tests (4 tests)
```

## Test Coverage

### `repository.tftest.hcl` - Main Module (20 tests)
1. ✅ Basic repository creation
2. ✅ Private repository with security features
3. ✅ Merge strategies configuration
4. ✅ Branches and default branch configuration
5. ✅ GitHub Actions configuration
6. ✅ Secrets and variables
7. ✅ Issue labels
8. ✅ Deploy keys
9. ✅ Autolink references
10. ✅ Teams and users collaborators
11. ✅ GitHub Pages (legacy)
12. ✅ Template repository
13. ✅ Custom properties
14. ✅ Topics configuration
15. ✅ Alias (renaming) functionality
16. ✅ Archived repository
17. ✅ Visibility logic with private parameter
18. ✅ Security scanning with public repository
19. ✅ Independent Dependabot secrets
20. ✅ Repository features configuration

### `environment.tftest.hcl` - Environment Submodule (10 tests)
1. ✅ Basic environment without configuration
2. ✅ Environment with reviewers (teams and users)
3. ✅ Environment with wait timer
4. ✅ Environment with deployment policies
5. ✅ Environment with secrets and variables
6. ✅ Multiple environments
7. ✅ Environment with prevent_self_review
8. ✅ Environment with can_admins_bypass
9. ✅ Environment with protected branches only
10. ✅ Environment variables with different types

### `ruleset.tftest.hcl` - Ruleset Submodule (18 tests)
1. ✅ Ruleset básico para branches
2. ✅ Ruleset con enforcement disabled
3. ✅ Ruleset para tags
4. ✅ Ruleset con bypass actors (roles)
5. ✅ Ruleset con bypass teams
6. ✅ Pull request rules
7. ✅ Required status checks
8. ✅ Required code scanning
9. ✅ Commit message patterns
10. ✅ Branch name pattern
11. ✅ Forbidden operations
12. ✅ Required deployments
13. ✅ Required linear history
14. ✅ Required signatures
15. ✅ Include/exclude patterns con ~ prefix
16. ✅ Múltiples rulesets complejos
17. ✅ Bypass organization admin
18. ✅ Enforcement evaluate

### `webhook.tftest.hcl` - Webhook Submodule (12 tests)
1. ✅ Basic webhook
2. ✅ Webhook with JSON content type
3. ✅ Webhook with form content type
4. ✅ Webhook with secret
5. ✅ Webhook with insecure SSL
6. ✅ Secure webhook (verified SSL)
7. ✅ Multiple webhooks
8. ✅ Webhook with all events
9. ✅ Webhook for push only
10. ✅ Webhook for complete CI/CD
11. ✅ Webhook for issue notifications
12. ✅ Webhook for deployment automation

### `file.tftest.hcl` - File Submodule (15 tests)
1. ✅ Basic file with inline content
2. ✅ File from external file
3. ✅ File in specific branch
4. ✅ File with custom commit
5. ✅ Multiple files
6. ✅ Complete .gitignore file
7. ✅ JSON configuration file
8. ✅ YAML file
9. ✅ Multiple files in different branches
10. ✅ Complete README file
11. ✅ License file
12. ✅ File with overwrite
13. ✅ Documentation files
14. ✅ GitHub issue template file
15. ✅ Dynamically generated file

### `integration.tftest.hcl` - Integration Tests (4 tests)
1. ✅ Complete repository with all features
2. ✅ Complete enterprise private repository
3. ✅ Open source repository with community configuration
4. ✅ Monorepo with multiple rulesets and environments

**Total: 79 tests**

## Running Tests

### Run all tests

```bash
terraform test
```

### Run a specific test file

```bash
terraform test tests/repository.tftest.hcl
terraform test tests/environment.tftest.hcl
terraform test tests/ruleset.tftest.hcl
terraform test tests/webhook.tftest.hcl
terraform test tests/file.tftest.hcl
terraform test tests/integration.tftest.hcl
```

### Run with verbose output

```bash
terraform test -verbose
```

### Run only tests matching a pattern

```bash
# Requires Terraform >= 1.7
terraform test -filter=repository
```

## Mock Providers

Tests use **mock providers** to simulate the GitHub API without making real calls. This enables:

- ✅ Fast tests without requiring credentials
- ✅ Tests without creating real resources in GitHub
- ✅ Reproducible and deterministic tests
- ✅ CI/CD friendly
- ✅ No token configuration required

Mock providers are defined in each test file:

```hcl
mock_provider "github" {}
mock_provider "tls" {}
mock_provider "null" {}
mock_provider "local" {}
```

## Assertions

Each test uses `assert` blocks to verify:

- Values of created resources
- Resource counts
- Specific configurations
- Conditional logic
- Computed values

Example:

```hcl
assert {
  condition     = github_repository.this.name == var.name
  error_message = "Repository name should match input variable"
}
```

## Requirements

- **Terraform >= 1.6.0**: Native tests with mock providers
- No GitHub credentials required
- No additional configuration required

## CI/CD Integration

These tests can be run in CI/CD pipelines without additional configuration:

### GitHub Actions

```yaml
name: Terraform Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0
      - run: terraform init
      - run: terraform test
```

### GitLab CI

```yaml
test:
  image: hashicorp/terraform:1.6
  script:
    - terraform init
    - terraform test
```

## Best Practices

1. **Use mock providers**: Don't use real credentials in tests
2. **Atomic tests**: Each test should verify a specific feature
3. **Clear assertions**: Descriptive error messages
4. **Complete coverage**: Test normal cases and edge cases
5. **Keep tests updated**: Update when you change the module

## Debugging

To see more information during test execution:

```bash
# View detailed plan
terraform test -verbose

# View Terraform logs
TF_LOG=DEBUG terraform test

# Run only a specific test by name
terraform test -filter="basic_repository_creation"
```

## Contributing

When adding new features to the module:

1. ✅ Add corresponding tests
2. ✅ Verify that all tests pass
3. ✅ Update this README if you add new test files
4. ✅ Ensure tests use mock providers

## References

- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Mock Providers](https://developer.hashicorp.com/terraform/language/tests#mock-providers)
- [Assertions](https://developer.hashicorp.com/terraform/language/tests#assertions)
