# Simple Example

Minimal configuration for getting started with the GitHub Governance module in organization mode.

## What This Example Does

- Manages a GitHub organization with basic settings
- Creates repositories using **presets** (simplified configuration)
- Demonstrates manual configuration alongside presets
- Configures a runner group
- Sets organization-level variables

## ✨ Using Presets

This example demonstrates the **preset feature** that drastically reduces code:

**Before (manual configuration):**
```hcl
"my-api" = {
  description                            = "Backend API service"
  visibility                             = "private"
  has_issues                             = true
  has_projects                           = false
  has_wiki                               = false
  delete_branch_on_merge                 = true
  enable_vulnerability_alerts            = true
  enable_secret_scanning                 = true
  enable_secret_scanning_push_protection = true
  # ... 15+ more attributes
}
```

**After (using preset):**
```hcl
"my-api" = {
  preset      = "secure-service"  # All security features pre-configured!
  description = "Backend API service"
}
```

**Reduces code by 80%!** 🚀

## Prerequisites

1. GitHub Personal Access Token with required scopes
2. Access to a GitHub organization
3. Terraform >= 1.6

## Usage

1. **Copy the example**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars`**
   ```hcl
   name          = "your-organization-name"
   billing_email = "billing@example.com"
   github_token  = "ghp_your_token_here"
   ```

3. **Initialize and apply**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Available Presets

| Preset | Best For | Key Features |
|--------|----------|--------------|
| `secure-service` | Backend APIs, microservices | Security scanning, branch protection, private |
| `public-library` | Open source packages | Public, issues, discussions, wikis |
| `documentation` | Docs sites, knowledge bases | GitHub Pages, public, simplified workflow |
| `infrastructure` | Terraform, IaC repos | Security+, branch protection, signatures |

## What Gets Created

- ✅ Organization settings (email, default permissions)
- ✅ Four repositories using different presets
- ✅ Runner group `default-runners` (accessible to all repos)
- ✅ Organization variable `ENVIRONMENT` set to `production`

## Costs

- **Free Plan**: ✅ Compatible (no webhooks or custom roles used)
- **GitHub Actions**: Depends on runner usage
- **Terraform**: Free to use

## Next Steps

After successfully applying this example:

1. **Add more repositories** by extending the `repositories` map
2. **Configure secrets** using `secrets_encrypted` variable
3. **Explore [complete example](../complete/)** for advanced features
4. **Try [project mode](../mode-comparison/)** for scoped management

## Cleanup

To remove all resources:

```bash
terraform destroy
```

**Note:** This will delete the repositories. Back up any important data first.
