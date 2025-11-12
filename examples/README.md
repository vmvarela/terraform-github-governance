# Examples Directory

This directory contains comprehensive examples demonstrating different use cases and scales of the terraform-github-governance module.

## Available Examples

### 🚀 [simple/](simple/)
**Basic module usage** - Perfect starting point for new users.

- **Use case**: Small teams or proof-of-concept
- **Scale**: 5 repositories
- **Features**: Basic repository management, minimal configuration
- **Complexity**: ⭐ Beginner
- **Lines of code**: ~100

**When to use:**
- Learning the module basics
- Testing module functionality
- Small projects or personal organizations

---

### 🎯 [complete/](complete/)
**Comprehensive feature showcase** - Production-ready configuration demonstrating all module capabilities.

- **Use case**: Full-featured GitHub organization management
- **Scale**: 10-20 repositories
- **Features**: All resources (rulesets, environments, teams, secrets, variables, labels, branches, webhooks)
- **Complexity**: ⭐⭐⭐ Advanced
- **Lines of code**: ~800

**When to use:**
- Production deployments
- Organizations needing full governance
- Reference for all available features
- Understanding advanced configurations

---

### 📈 [large-scale/](large-scale/)
**Enterprise-scale deployment** - Optimized for managing 100+ repositories efficiently.

- **Use case**: Large organizations with multiple teams and domains
- **Scale**: **100 repositories** (40 backend + 20 frontend + 15 infra + 15 data + 10 mobile + 5 public)
- **Features**:
  - DRY configuration via settings cascade
  - Domain-driven repository organization
  - Organization-wide compliance rulesets
  - Team-based access control
  - Performance optimization patterns
- **Complexity**: ⭐⭐⭐⭐ Expert
- **Lines of code**: ~500 (manages 100 repos!)

**When to use:**
- Enterprise GitHub organizations
- Multi-team environments
- Need for centralized security policies
- Scaling beyond 50 repositories
- Performance and efficiency critical

**Key features:**
- **DRY efficiency**: Configure 100 repos with ~15 lines of defaults
- **Domain organization**: Microservices grouped by business domain
- **Org-wide rulesets**: 4 rulesets enforce compliance across all repos
- **Performance**: Single `terraform apply` manages all repos (5-10 min)

---

### 🛡️ [rulesets-advanced/](rulesets-advanced/)
**Complete ruleset edge cases** - Demonstrates ALL GitHub ruleset features and patterns.

- **Use case**: Understanding and implementing complex branch/tag protection rules
- **Scale**: 5 test repositories
- **Features**: **20 edge case categories** covering every ruleset feature:
  1. All enforcement levels (active/evaluate/disabled)
  2. Complex ref patterns (~DEFAULT_BRANCH, ~ALL, wildcards)
  3. All bypass actor types
  4. Comprehensive PR rules
  5. Multiple status checks
  6. Commit/author/committer email patterns
  7. Branch name patterns (all operators)
  8. Tag name patterns (semver, calver)
  9. All boolean rules
  10. Required deployments
  11. Code scanning requirements (all thresholds)
  12. Pattern negation
  13. Special regex characters
  14. And more...
- **Complexity**: ⭐⭐⭐⭐⭐ Expert Reference
- **Lines of code**: ~1,000 (comprehensive documentation)

**When to use:**
- Implementing complex branch protection
- Understanding GitHub ruleset capabilities
- Copy-paste patterns for specific scenarios
- Security and compliance requirements
- Reference documentation for all ruleset features

**Key features:**
- **Complete coverage**: Every GitHub ruleset feature demonstrated
- **Real patterns**: Copy-paste ready configurations
- **Edge cases**: Anti-patterns and gotchas documented
- **Testing aid**: Includes test repositories for validation

---

## Example Selection Guide

Choose your example based on your needs:

```
┌─────────────────────────────────────────────────────────────────┐
│ Your Situation              │ Recommended Example               │
├─────────────────────────────┼───────────────────────────────────┤
│ Just getting started        │ simple/                           │
│ Learning all features       │ complete/                         │
│ Production deployment       │ complete/                         │
│ 50+ repositories            │ large-scale/                      │
│ Enterprise org (100+ repos) │ large-scale/                      │
│ Complex branch protection   │ rulesets-advanced/                │
│ Security compliance needs   │ rulesets-advanced/ + complete/    │
│ Performance optimization    │ large-scale/                      │
│ Multi-team organization     │ large-scale/                      │
└─────────────────────────────┴───────────────────────────────────┘
```

## Quick Start

### 1. Choose an Example

```bash
cd examples/simple    # For beginners
cd examples/complete  # For production
cd examples/large-scale    # For enterprise scale
cd examples/rulesets-advanced  # For ruleset patterns
```

### 2. Configure

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Review changes
terraform plan

# Apply configuration
terraform apply

# View outputs
terraform output
```

## Architecture Patterns

### Settings Cascade (DRY Configuration)

All examples leverage the **priority model** for efficient configuration:

```
Priority: settings > repository > defaults
```

**Example from large-scale/**:

```hcl
# Defaults: Base configuration for ALL repositories
defaults = {
  visibility             = "private"
  delete_branch_on_merge = true
}

# Settings: Override defaults (policy enforcement)
settings = {
  enable_vulnerability_alerts = true  # Enforced on all repos
  enable_dependabot_security_updates = true
}

# Repositories: Override per-repo when needed
repositories = {
  "public-docs" = {
    visibility = "public"  # Override default "private"
  }
}
```

Result: 100 repositories configured with minimal repetition.

### Domain-Driven Organization

**From large-scale/main.tf**:

```hcl
repositories = merge(
  # Backend microservices (40 repos)
  { for i in range(40) :
    "backend-service-${format("%03d", i)}" => {
      description = "Service ${i} - ${local.service_domains[i % 8]}"
      teams = {
        "team-${local.service_domains[i % 8]}" = "push"
      }
    }
  },

  # Frontend apps (20 repos)
  { for i in range(20) : /* ... */ },

  # Infrastructure (15 repos)
  { for i in range(15) : /* ... */ }
)
```

Organizes 100 repositories by business domain with clear ownership.

### Organization-Wide Rulesets

**From rulesets-advanced/main.tf**:

```hcl
rulesets = {
  "main-branch-protection" = {
    enforcement = "active"
    conditions = {
      ref_name = { include = ["~DEFAULT_BRANCH"] }  # ALL main branches
    }
    rules = {
      pull_request = {
        required_approving_review_count = 1
      }
    }
  }
}
```

Single ruleset applies to all repositories in the organization.

## Performance Characteristics

Measured performance for each example:

| Example | Repos | Plan Time | Apply Time | State Size | Memory |
|---------|-------|-----------|------------|------------|--------|
| simple | 5 | ~10s | ~2 min | ~100 KB | ~200 MB |
| complete | 15 | ~20s | ~5 min | ~500 KB | ~300 MB |
| large-scale | 100 | ~45s | ~8 min | ~2.5 MB | ~500 MB |
| rulesets-advanced | 5 | ~15s | ~3 min | ~200 KB | ~250 MB |

**Notes:**
- Times measured on MacBook Pro M1, local execution
- Includes initial resource creation
- Subsequent applies are typically 2-3x faster

## Common Customizations

### Adding More Repositories

All examples use Terraform's `for` expressions for easy scaling:

```hcl
# Add 10 more repositories
{ for i in range(10, 20) :  # Start from 10, add 10 more
  "new-service-${format("%02d", i)}" => {
    description = "New service ${i}"
  }
}
```

### Changing Security Policies

Modify `settings` block to affect all repositories:

```hcl
settings = {
  enable_vulnerability_alerts = true  # Enforce everywhere
  enable_secret_scanning_push_protection = true

  issue_labels = {
    "security" = "ee0701"  # Add to all repos
  }
}
```

### Adding Organization Rulesets

Add to `rulesets` block to create org-wide rules:

```hcl
rulesets = {
  "my-custom-rule" = {
    enforcement = "active"
    target      = "branch"

    conditions = {
      ref_name = { include = ["~ALL"] }  # All branches
    }

    rules = {
      required_linear_history = true  # Enforce everywhere
    }
  }
}
```

## Troubleshooting

### Example Won't Apply

1. **Check GitHub permissions**: Token needs `admin:org` scope
2. **Verify organization exists**: `gh api orgs/YOUR_ORG`
3. **Check rate limits**: `gh api rate_limit`
4. **Review state**: `terraform show`

### Performance Issues

For large-scale deployments:

```bash
# Increase parallelism
terraform apply -parallelism=20

# Use targeted applies during development
terraform apply -target=module.github_org.github_repository.repo["specific-repo"]

# Enable debug logging
TF_LOG=DEBUG terraform apply
```

### Rate Limiting

GitHub API rate limits:
- **Personal Access Token**: 5,000 requests/hour
- **GitHub App**: 15,000 requests/hour (recommended for large-scale)

Switch to GitHub App authentication in provider config:

```hcl
provider "github" {
  owner = "your-org"
  app_auth {
    id              = var.github_app_id
    installation_id = var.github_app_installation_id
    pem_file        = file("${path.module}/github-app.pem")
  }
}
```

## Testing Examples

All examples can be tested safely:

```bash
# 1. Use a test organization (not production!)
github_org = "my-test-org"

# 2. Start with plan only
terraform plan -out=tfplan

# 3. Review carefully before applying
terraform show tfplan

# 4. Apply with auto-approve only after verification
terraform apply tfplan

# 5. Destroy when done testing
terraform destroy
```

## Contributing

When adding new examples:

1. **Follow naming convention**: `lowercase-with-dashes/`
2. **Include all files**:
   - `main.tf` - Main configuration
   - `variables.tf` - Input variables
   - `outputs.tf` - Output values
   - `terraform.tfvars.example` - Example values
   - `README.md` - Comprehensive documentation
3. **Document thoroughly**: Explain use case, features, when to use
4. **Test before committing**: Verify with `terraform plan`
5. **Update this README**: Add entry in table above

## Related Documentation

- **[Module README](../README.md)**: Module usage and features
- **[EXPERT_ANALYSIS_V2.md](../EXPERT_ANALYSIS_V2.md)**: Architecture deep-dive
- **[ADRs](../docs/adr/)**: Architecture decision records
- **[Tests](../tests/)**: Automated test suite

## Support

For issues or questions:
- Create an issue: https://github.com/your-org/terraform-github-governance/issues
- Review existing examples in this directory
- Check EXPERT_ANALYSIS_V2.md for architecture guidance

## License

Apache 2.0 - See [LICENSE](../LICENSE) for details.
