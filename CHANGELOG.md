# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Global user permission optimization feature
  - Automatically creates teams when 2+ users share same role (project mode)
  - Reduces API calls by up to 88% for large user bases
  - Documentation: `docs/USER_OPTIMIZATION.md`

### Changed
- None

### Deprecated
- None

### Removed
- None

### Fixed
- None

### Security
- None

---

## [1.0.0] - 2024-11-12

### Added

#### Core Features
- **Dual-mode architecture**: Organization-wide and project-scoped management
- **Plan-aware validation**: Automatic feature detection based on GitHub plan
- **Settings cascade**: Three-tier configuration (repository > settings > defaults)

#### Organization Resources
- `github_organization_settings` - Organization configuration
- `github_organization_webhook` - Organization-level webhooks
- `github_organization_security_manager` - Security management delegation
- `github_organization_custom_properties` - Repository metadata schema (Enterprise Cloud)
- `github_workflow_repository_permissions` - Workflow permission controls
- `github_organization_custom_role` - Custom repository roles (deprecated by provider)
- `github_organization_role` - Organization-wide custom roles
- `github_organization_role_user` - User role assignments
- `github_organization_role_team` - Team role assignments

#### Repository Resources
- `github_repository` - Repository management with 50+ configuration options
- `github_repository_environment` - Deployment environments
- `github_repository_ruleset` - Branch and tag protection rules
- `github_repository_webhook` - Repository webhooks
- `github_repository_deploy_key` - Auto-generated deploy keys with TLS
- `github_repository_file` - File management in repositories
- `github_repository_autolink_reference` - Autolink references
- `github_repository_dependabot_security_updates` - Dependabot configuration
- `github_repository_collaborators` - User and team access management
- `github_branch_default` - Default branch configuration
- `github_branch_protection` - Legacy branch protection
- `github_issue_labels` - Issue label management
- `github_actions_repository_access_level` - Actions access control
- `github_actions_repository_permissions` - Repository-level Actions permissions

#### GitHub Actions Resources
- `github_actions_runner_group` - Runner group management (organization and project modes)
- `github_actions_organization_variable` - Organization-level variables
- `github_actions_organization_secret` - Organization-level secrets (plaintext and encrypted)

#### Dependabot Resources
- `github_dependabot_organization_secret` - Organization-level Dependabot secrets

#### Advanced Features
- **Lifecycle protection**: `prevent_destroy` on critical resources
- **Auto-generated deploy keys**: TLS private keys for repositories
- **Secret scanning logic**: Conditional enablement based on visibility and Advanced Security
- **Repository archiving**: Safe archival with config retention
- **Team management**: Automatic team creation and membership management

#### Testing
- 99 comprehensive tests using Terraform native testing framework
- 94% resource coverage (31/33 resources)
- 100% variable and output coverage
- Mock providers for fast, reliable testing

#### Documentation
- Comprehensive README with examples
- Architecture Decision Records (ADRs)
- Performance optimization guide
- Error code reference with solutions
- Migration guides and advanced examples
- Security best practices
- Troubleshooting playbook

### Changed
- Refactored complex locals into readable, step-by-step transformations
- Separated organization-exclusive resources into `organization.tf`
- Improved output structure with summary and raw outputs
- Enhanced validation messages with solutions and documentation links

### Deprecated
- `github_organization_custom_role` - Provider deprecated this resource in favor of `github_organization_repository_role`

### Removed
- `modules/repository` - Integrated into main module for simplicity
- `modules/actions-runner-scale-set` - Removed Kubernetes/Helm dependencies
- `modules/suborg` - Removed unused submodule
- `modules/webhook` - Integrated into main module

### Fixed
- State management issues with repository collaborators
- Visibility logic for secret scanning on private repositories
- Runner group visibility in project mode
- Organization role ID mapping for assignments

### Security
- All secret variables marked as `sensitive = true`
- Lifecycle protection on critical resources
- Documented GitHub App setup (recommended over PAT)
- State encryption requirements documented
- Audit logging procedures established

---

## Release Notes Format

This project follows [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Commit Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring without feature changes
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Maintenance tasks
- **ci**: CI/CD changes
- **build**: Build system changes
- **revert**: Revert previous commit

### Examples

```
feat(org): add support for organization custom properties
fix(repo): resolve visibility logic for secret scanning
docs(readme): update authentication examples
refactor(locals): simplify repository configuration merge
perf(api): reduce API calls with user optimization
test(repository): add tests for deploy keys
```

### Breaking Changes

Breaking changes are denoted with `BREAKING CHANGE:` in the commit body:

```
feat(api)!: change variable structure for repositories

BREAKING CHANGE: The `repositories` variable now requires explicit visibility.
Migration guide available at docs/MIGRATION.md
```

---

## Upgrade Guides

### Upgrading to 1.x from Pre-release

**No breaking changes** - This is the initial stable release.

---

## Version Support

| Version | Status | Support Until | Notes |
|---------|--------|---------------|-------|
| 1.x     | ✅ Active | TBD | Current stable release |
| 0.x     | ❌ Deprecated | 2024-12-31 | Pre-release versions |

---

## GitHub Provider Compatibility

| Module Version | GitHub Provider | Terraform |
|----------------|-----------------|-----------|
| 1.x            | ~> 6.0          | >= 1.6    |

---

## Links

- [GitHub Repository](https://github.com/vmvarela/terraform-github-governance)
- [Terraform Registry](https://registry.terraform.io/modules/vmvarela/governance/github)
- [Issues](https://github.com/vmvarela/terraform-github-governance/issues)
- [Discussions](https://github.com/vmvarela/terraform-github-governance/discussions)

---

**Maintained by**: [Your Name/Organization]
**License**: MIT
**Changelog Format**: [Keep a Changelog](https://keepachangelog.com/)
**Versioning**: [Semantic Versioning](https://semver.org/)
