# terraform-github-governance
A comprehensive Terraform module for applying consistent governance to a GitHub organization and its repositories

## Prerequisites

### Initial Setup: Import Existing Organization

**Important:** Before your first `terraform apply`, you must import the existing GitHub organization settings resource to avoid conflicts:

```bash
# Import organization settings (replace 'your-org-name' with your actual organization name)
terraform import 'module.github.github_organization_settings.this[0]' your-org-name
```

**Why is this needed?**
- GitHub organizations already exist before Terraform manages them
- The `github_organization_settings` resource manages organization-level settings
- Without importing, Terraform will try to create it and fail with a `422` error
- You only need to do this **once** per organization

**When to import:**
- First time using this module with an existing organization
- When you see errors like: `Error: POST https://api.github.com/orgs/your-org 422`

### Required GitHub Token Scopes

This module requires a GitHub Personal Access Token (PAT) with the following scopes:

| Scope | Required | Purpose |
|-------|----------|---------|
| `admin:org` | ✅ Yes | Manage organization settings, webhooks, secrets, variables |
| `repo` | ✅ Yes | Manage repositories, branches, and repository settings |
| `workflow` | ✅ Yes | Manage GitHub Actions workflows and runner groups |
| `read:packages` | ⚠️ Recommended | Read package metadata (if using GitHub Packages) |

**Note:** The `github_organization` data source used for plan validation works with the `admin:org` scope. No additional scopes like `user:email` or `read:user` are required.

### Creating a GitHub Token

1. Go to **GitHub Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token** (classic)
3. Select the required scopes listed above
4. Set an appropriate expiration date
5. Generate and securely store the token

**Security Best Practice:** Use the token via environment variable:
```bash
export TF_VAR_github_token="your_token_here"
```

## Plan Requirements and Limitations

This module includes automatic validation to detect when you're trying to use features that require paid GitHub plans. You'll receive clear warnings during `terraform plan` if your organization plan doesn't support certain features.

### Resources Requiring GitHub Team or Business Plan

The following features are **NOT available** on GitHub Free organizations:

| Feature | Variable | Required Plan | Terraform Resource |
|---------|----------|---------------|-------------------|
| **Organization Webhooks** | `webhooks` | Team/Business/Enterprise | `github_organization_webhook` |
| **Organization Rulesets** | `rulesets` | Team/Business/Enterprise | `github_organization_ruleset` |

**What happens if you use these on Free plan:**
- The module will show a **warning** during `terraform plan` with clear error messages
- The `terraform apply` will fail with a `404 Not Found` error from GitHub API
- You'll see guidance on alternatives or upgrade paths

**Solutions for Free organizations:**
1. **Webhooks**: Use repository-level webhooks (configure in each repository's settings)
2. **Rulesets**: Use repository-level branch protection rules instead

### Resources Requiring GitHub Enterprise Plan

| Feature | Variable | Required Plan | Terraform Resource |
|---------|----------|---------------|-------------------|
| **Custom Repository Roles** | `repository_roles` | Enterprise | `github_organization_repository_role` |

**What happens if you use this without Enterprise:**
- Warning during `terraform plan`
- API will reject the request with appropriate error

**Solution for non-Enterprise organizations:**
- Use standard GitHub roles: `read`, `triage`, `write`, `maintain`, `admin`

### Example Validation Warning

When using a feature that requires a paid plan, you'll see:

```
Warning: Check block assertion failed

  on main.tf line 144, in check "organization_plan_validation":
 144:     condition = length(var.webhooks) == 0 || local.github_plan != "free"

❌ Organization webhooks require GitHub Team, Business, or Enterprise plan.
Current plan: free

Solutions:
  1. Remove the 'webhooks' configuration from your module
  2. Use repository-level webhooks instead (configure in each repository)
  3. Upgrade your organization plan at: https://github.com/organizations/your-org/settings/billing

Error occurs at: github_organization_webhook resource
```

### Checking Your Organization Plan

You can verify your organization's plan before applying:

```bash
# Using the provided script
./scripts/check-org-plan.sh your-org-name

# Or manually via API
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/orgs/your-org | jq '.plan.name'
```

