# Complete Example

Comprehensive example showcasing all features of the GitHub Governance module.

## Features Demonstrated

### Organization Management
- ✅ Organization settings (billing, permissions, security)
- ✅ Member permissions and project settings
- ✅ Advanced security defaults

### Repository Management
- ✅ Multiple repositories with varied configurations
- ✅ Repository-specific settings overrides
- ✅ Team and user access control
- ✅ Branch protection and rulesets

### GitHub Actions
- ✅ Multiple runner groups with different configurations
- ✅ Workflow restrictions
- ✅ Repository-specific runner access
- ✅ Organization variables and encrypted secrets

### Enterprise Features (if available)
- ✅ Organization webhooks (Team+ plan)
- ✅ Custom repository roles (Enterprise plan)
- ✅ Internal repositories (Business+ plan)
- ✅ Organization rulesets (Team+ plan)

## Prerequisites

1. GitHub Personal Access Token with required scopes
2. GitHub organization with appropriate plan:
   - Free: Basic features only
   - Team: Webhooks and rulesets
   - Enterprise: Custom roles and advanced features

## Usage

### 1. Set Up Variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
name          = "your-org"
billing_email = "billing@example.com"
github_token  = "ghp_your_token"
github_plan   = "free"  # or "team", "business", "enterprise"
```

### 2. Review Configuration

The example adapts based on your organization plan. Review `main.tf` to see which features will be enabled.

### 3. Apply Configuration

```bash
terraform init
terraform plan  # Review changes
terraform apply
```

## Plan-Specific Features

### Free Plan
- Organization settings
- Public and private repositories
- Runner groups
- Variables and encrypted secrets

### Team Plan (adds)
- Organization webhooks
- Organization rulesets
- Advanced branch protection

### Business Plan (adds)
- Internal repositories
- SAML SSO integration

### Enterprise Plan (adds)
- Custom repository roles
- Advanced security features
- Audit log streaming

## What Gets Created

This example creates:

- 📋 **Organization Settings**: Configured security defaults
- 📦 **5 Repositories**: Mix of public, private, and internal (if Enterprise)
- 🏃 **3 Runner Groups**: Default, production, and CI runners
- 🔐 **Secrets**: Example encrypted secrets
- 📊 **Variables**: Shared variables across repositories
- 🔗 **Webhooks**: Organization webhook (if Team+)
- 👥 **Custom Roles**: Example custom role (if Enterprise)
- ⚖️ **Rulesets**: Branch protection and required workflows (if Team+)

## Customization

### Adding Repositories

```hcl
repositories = {
  "new-repo" = {
    description = "My new repository"
    visibility  = "private"
    has_issues  = true
  }
}
```

### Adding Secrets

```hcl
secrets_encrypted = {
  "API_KEY" = "base64_encrypted_value"
}
```

Encrypt secrets using:
```bash
gh secret set API_KEY --body "my-secret-value"
```

### Modifying Runner Groups

```hcl
runner_groups = {
  "production" = {
    visibility   = "selected"
    repositories = ["critical-app", "api-service"]
    workflows    = [".github/workflows/deploy.yml"]
  }
}
```

## Costs

- **Terraform**: Free
- **GitHub**: Depends on your plan and usage
- **Actions Minutes**: Based on runner usage

## Troubleshooting

### Plan-Related Errors

If you see errors about unsupported features:

1. Check your organization plan:
   ```bash
   curl -H "Authorization: token $GITHUB_TOKEN" \
     https://api.github.com/orgs/your-org | jq '.plan.name'
   ```

2. Update `github_plan` variable in `terraform.tfvars`

3. Remove unsupported features from configuration

### Common Issues

**422 Error on Organization Settings**
- Solution: Import existing organization first:
  ```bash
  terraform import 'module.github.github_organization_settings.this[0]' your-org
  ```

**Webhook Creation Fails**
- Solution: Upgrade to Team or higher plan, or remove webhooks configuration

**Custom Roles Not Available**
- Solution: Requires Enterprise plan

## Next Steps

1. **Explore [project mode](../mode-comparison/)** for scoped management
2. **Review [submodules](../../modules/)** for standalone usage
3. **Check [repository references](../repository-references/)** for advanced patterns

## Cleanup

```bash
terraform destroy
```

⚠️ **Warning**: This will delete all created repositories and configurations. Ensure you have backups.
