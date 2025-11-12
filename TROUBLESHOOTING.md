# Troubleshooting Guide

## Overview

This guide provides solutions to common issues when using the Terraform GitHub Governance module.

## Table of Contents

- [Authentication Issues](#authentication-issues)
- [Permission Errors](#permission-errors)
- [State Management Issues](#state-management-issues)
- [Resource Creation Failures](#resource-creation-failures)
- [Plan Validation Errors](#plan-validation-errors)
- [Performance Issues](#performance-issues)
- [Import and Migration](#import-and-migration)
- [Getting Help](#getting-help)

---

## Authentication Issues

### Error: `401 Bad credentials`

**Symptom:**
```
Error: GET https://api.github.com/user: 401 Bad credentials []
```

**Causes & Solutions:**

1. **Token Expired or Invalid**
   ```bash
   # Verify token works
   curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user

   # If fails, regenerate token
   ```

2. **Wrong Token Type**
   ```hcl
   # ❌ Classic token used when fine-grained is configured
   # ✅ Ensure token type matches provider configuration

   provider "github" {
     owner = "my-org"
     token = var.github_token  # Use correct token type
   }
   ```

3. **GitHub App Authentication Issues**
   ```bash
   # Verify app credentials
   openssl rsa -in private-key.pem -check

   # Check installation ID
   curl -H "Authorization: Bearer <JWT>" \
        -H "Accept: application/vnd.github+json" \
        https://api.github.com/app/installations
   ```

**Fix:**
1. Regenerate credentials (see [SECURITY.md](SECURITY.md))
2. Update environment variables or tfvars
3. Run `terraform init -reconfigure`

---

### Error: `404 Not Found`

**Symptom:**
```
Error: GET https://api.github.com/orgs/my-org: 404 Not Found
```

**Causes & Solutions:**

1. **Organization Name Typo**
   ```hcl
   # ❌ Wrong
   module "github" {
     name = "my-ogr"  # Typo
   }

   # ✅ Correct
   module "github" {
     name = "my-org"
   }
   ```

2. **No Access to Organization**
   ```bash
   # Verify access
   gh api /orgs/my-org

   # Check if you're a member
   gh api /orgs/my-org/members -q '.[].login' | grep YOUR_USERNAME
   ```

3. **App Not Installed**
   - Go to: `https://github.com/organizations/my-org/settings/installations`
   - Verify the GitHub App is installed

**Fix:**
1. Correct organization name
2. Request organization access
3. Install GitHub App on organization

---

## Permission Errors

### Error: `403 Resource not accessible by integration`

**Symptom:**
```
Error: POST https://api.github.com/orgs/my-org/webhooks: 403 Resource not accessible by integration
```

**Causes & Solutions:**

1. **Insufficient GitHub App Permissions**

   Check and update app permissions:
   ```
   https://github.com/organizations/YOUR_ORG/settings/apps/YOUR_APP/permissions
   ```

   Required permissions (see [SECURITY.md](SECURITY.md#authentication-methods))

2. **PAT Missing Scopes**

   Fine-grained tokens:
   - Organization > Webhooks: Read & Write
   - Organization > Administration: Read & Write

   Classic tokens:
   - `admin:org` scope

3. **Organization Plan Limitations**
   ```hcl
   # Check plan in terraform output
   terraform output organization_plan

   # Verify feature availability
   terraform output features_available
   ```

**Fix:**
1. Update GitHub App permissions (requires re-installation approval)
2. Regenerate PAT with correct scopes
3. Upgrade organization plan or remove unsupported features

---

### Error: `You must be an administrator to create webhooks`

**Symptom:**
```
Error: POST https://api.github.com/orgs/my-org/hooks: 403 You must be an administrator to create webhooks
```

**Causes:**
- User/App lacks admin permissions on organization

**Fix:**

**For PAT:**
```bash
# Verify you're an owner
gh api /orgs/my-org/members/YOUR_USERNAME/membership \
  --jq '.role'  # Should be "admin"
```

**For GitHub App:**
1. Organization Settings > GitHub Apps
2. Click on your app
3. Verify "Administration" permission is "Read & write"
4. Accept permission change (requires admin approval)

---

## State Management Issues

### Error: `state lock` timeout

**Symptom:**
```
Error: Error acquiring the state lock
Lock Info:
  ID:        xxxxxxxxxx
  Path:      ...
  Operation: OperationTypeApply
  Who:       user@hostname
  Created:   2024-01-15 10:30:00 UTC
```

**Causes:**
- Another Terraform process is running
- Previous run crashed without releasing lock
- Network interruption during state operation

**Fix:**

1. **Wait for other process to complete**
   ```bash
   # Check if terraform is running
   ps aux | grep terraform
   ```

2. **Force unlock** (⚠️ use with caution):
   ```bash
   # Get lock ID from error message
   terraform force-unlock <LOCK_ID>
   ```

3. **Clean up stale locks** (S3 backend):
   ```bash
   # Check DynamoDB for locks
   aws dynamodb scan \
     --table-name terraform-locks \
     --filter-expression "attribute_exists(LockID)"
   ```

---

### Error: `state snapshot was created by Terraform v1.x`

**Symptom:**
```
Error: state snapshot was created by Terraform v1.7.0, which is newer than current v1.6.0
```

**Causes:**
- State created with newer Terraform version

**Fix:**

**DO NOT downgrade state!** Instead:

```bash
# Upgrade Terraform to match or exceed state version
tfenv install 1.7.0  # or brew install terraform
tfenv use 1.7.0

# Verify version
terraform version

# Continue operations
terraform plan
```

---

### Error: `state file is corrupted`

**Symptom:**
```
Error: Failed to load state: state snapshot is invalid
```

**Recovery:**

1. **Restore from backup** (S3 versioning):
   ```bash
   # List versions
   aws s3api list-object-versions \
     --bucket terraform-state \
     --prefix github-governance/

   # Download previous version
   aws s3api get-object \
     --bucket terraform-state \
     --key github-governance/terraform.tfstate \
     --version-id <VERSION_ID> \
     state-backup.tfstate

   # Restore
   terraform state push state-backup.tfstate
   ```

2. **Rebuild state** (last resort):
   ```bash
   # Remove corrupted state
   rm terraform.tfstate

   # Import existing resources
   terraform import module.github.github_organization_settings.this my-org
   terraform import module.github.github_repository.repo[\"repo-name\"] repo-name
   # ... repeat for all resources
   ```

---

## Resource Creation Failures

### Error: `repository already exists`

**Symptom:**
```
Error: POST https://api.github.com/orgs/my-org/repos: 422 Repository creation failed.
  name: ["name already exists on this account"]
```

**Causes:**
- Repository already exists in organization
- Name collision in project mode

**Fix:**

1. **Import existing repository**:
   ```bash
   terraform import 'module.github.github_repository.repo["repo-name"]' repo-name
   ```

2. **Use different name (project mode)**:
   ```hcl
   module "github" {
     spec = "myproject-%s"  # Adds prefix

     repositories = {
       "api" = {}  # Creates: myproject-api
     }
   }
   ```

3. **Check for archived repos**:
   ```bash
   gh repo list my-org --archived --json name
   ```

---

### Error: `team already exists`

**Symptom:**
```
Error: POST https://api.github.com/orgs/my-org/teams: 422 Validation Failed
  name: ["name has already been taken"]
```

**Causes:**
- Team created by global user optimization has name conflict

**Fix:**

1. **Import existing team**:
   ```bash
   terraform import 'module.github.github_team.global_role_teams["maintain"]' my-org/my-project-maintain
   ```

2. **Use different project name**:
   ```hcl
   module "github" {
     name = "team-platform-v2"  # Different name = different team names
   }
   ```

3. **Rename existing team** (via GitHub UI):
   - Navigate to: `https://github.com/orgs/my-org/teams/team-name/edit`
   - Change name
   - Run terraform apply

---

### Error: `secret scanning requires advanced security`

**Symptom:**
```
Error: PATCH https://api.github.com/repos/my-org/repo: 422 Secret scanning is only available for private repositories with GitHub Advanced Security enabled
```

**Causes:**
- Trying to enable secret scanning on private repo without Advanced Security
- Organization plan doesn't support Advanced Security

**Fix:**

1. **Check plan support**:
   ```bash
   terraform output features_available
   ```

2. **Enable Advanced Security**:
   ```hcl
   repositories = {
     "my-repo" = {
       visibility               = "private"
       enable_advanced_security = true  # Enable first
       enable_secret_scanning   = true  # Then this
     }
   }
   ```

3. **Or make repository public**:
   ```hcl
   repositories = {
     "my-repo" = {
       visibility             = "public"  # Free secret scanning
       enable_secret_scanning = true
     }
   }
   ```

---

## Plan Validation Errors

### Error: `[TF-GH-001] Organization webhooks require paid plan`

**Symptom:**
```
Error: Resource precondition failed

[TF-GH-001] ❌ Organization webhooks require GitHub Team, Business, or Enterprise plan.
Current plan: free
```

**Causes:**
- Organization on Free plan
- Trying to use paid-plan features

**Fix:**

1. **Remove unsupported features**:
   ```hcl
   # ❌ Remove
   webhooks = {
     "my-webhook" = { url = "..." }
   }
   ```

2. **Upgrade organization plan**:
   - Go to: `https://github.com/organizations/my-org/settings/billing/plans`
   - Choose Team, Business, or Enterprise

3. **Use repository webhooks instead**:
   ```hcl
   repositories = {
     "my-repo" = {
       webhooks = {
         "my-webhook" = { url = "..." }
       }
     }
   }
   ```

---

### Error: `[TF-GH-002] Rulesets require paid plan`

**Similar to TF-GH-001**

**Fix:**
1. Remove `rulesets` configuration
2. Upgrade organization plan
3. Use branch protection rules instead (available on all plans)

---

### Error: `repository name format invalid`

**Symptom:**
```
Error: Invalid repository name

Repository name can only contain alphanumeric characters, hyphens, underscores, and periods
```

**Causes:**
- Special characters in repository name
- Project mode spec with invalid format

**Fix:**

```hcl
# ❌ Invalid
repositories = {
  "my repo!" = {}  # Spaces and ! not allowed
}

# ✅ Valid
repositories = {
  "my-repo" = {}  # Hyphens OK
  "my_repo" = {}  # Underscores OK
  "my.repo" = {}  # Periods OK
}

# Project mode: spec is sanitized automatically
spec = "project-$%#-%s"  # Becomes: "project-%s"
```

---

## Performance Issues

### Slow `terraform plan` (5+ minutes)

**Causes:**
- Large number of repositories (100+)
- Many data sources
- Complex locals evaluation

**Optimization:**

1. **Use parallelism**:
   ```bash
   terraform plan -parallelism=20
   ```

2. **Cache data sources**:
   ```hcl
   # Provide info_repositories to avoid API call
   module "github" {
     info_repositories = {
       names    = ["repo1", "repo2", ...]
       repo_ids = [123, 456, ...]
     }
   }
   ```

3. **Split into multiple workspaces**:
   ```
   workspace-1: repos 1-50
   workspace-2: repos 51-100
   workspace-3: repos 101-150
   ```

See [PERFORMANCE.md](docs/PERFORMANCE.md) for detailed strategies.

---

### Error: `429 API rate limit exceeded`

**Symptom:**
```
Error: GET https://api.github.com/repos/my-org/repo: 403 API rate limit exceeded
```

**Causes:**
- Too many API calls in short time
- Multiple Terraform runs in parallel
- Large number of resources

**Fix:**

1. **Check rate limit status**:
   ```bash
   curl -H "Authorization: token $GITHUB_TOKEN" \
        https://api.github.com/rate_limit
   ```

2. **Use GitHub App** (higher limits):
   - PAT: 5,000 requests/hour
   - GitHub App: 15,000 requests/hour

3. **Add delays**:
   ```bash
   terraform plan
   sleep 60  # Wait 1 minute
   terraform apply
   ```

4. **Reduce parallelism**:
   ```bash
   terraform apply -parallelism=5
   ```

---

## Import and Migration

### Importing Existing Repositories

**Scenario:** You have existing GitHub resources managed manually, want to import into Terraform.

**Steps:**

1. **Define in Terraform**:
   ```hcl
   module "github" {
     repositories = {
       "existing-repo" = {
         description = "My repo"
       }
     }
   }
   ```

2. **Import repository**:
   ```bash
   terraform import 'module.github.github_repository.repo["existing-repo"]' existing-repo
   ```

3. **Import related resources**:
   ```bash
   # Branch protection
   terraform import 'module.github.github_repository_ruleset.repo["existing-repo"]' \
     'existing-repo:ruleset-id'

   # Environments
   terraform import 'module.github.github_repository_environment.repo["existing-repo:production"]' \
     'existing-repo:production'

   # Deploy keys
   terraform import 'module.github.github_repository_deploy_key.this["existing-repo:deploy"]' \
     'existing-repo:key-id'
   ```

4. **Verify**:
   ```bash
   terraform plan  # Should show no changes
   ```

---

### Migrating from Manual to IaC

**See:** [examples/advanced/migration-from-manual](examples/advanced/migration-from-manual)

**Quick Guide:**

1. **Audit existing resources**:
   ```bash
   # List all repos
   gh repo list my-org --limit 1000 --json name,visibility,isArchived

   # Export to CSV
   gh repo list my-org --limit 1000 --json name,description,visibility \
     --jq '.[] | [.name, .description, .visibility] | @csv' > repos.csv
   ```

2. **Generate Terraform config**:
   ```python
   # Use script to generate from CSV
   python generate-terraform-config.py repos.csv > repositories.tf
   ```

3. **Import in batches**:
   ```bash
   # Import 10 repos at a time
   ./import-batch.sh repos-1-10.txt
   ./import-batch.sh repos-11-20.txt
   ```

4. **Reconcile differences**:
   ```bash
   terraform plan > plan-output.txt

   # Review changes
   grep -E "^\s+[~+-]" plan-output.txt
   ```

---

## Common Error Messages Reference

| Error Code | Message | Solution |
|------------|---------|----------|
| TF-GH-001 | Webhooks require paid plan | Upgrade plan or remove webhooks |
| TF-GH-002 | Rulesets require paid plan | Upgrade plan or use branch protection |
| TF-GH-003 | Custom properties require Enterprise Cloud | Upgrade or remove custom_properties |
| TF-GH-004 | Internal repos require Business/Enterprise | Change visibility or upgrade |
| TF-GH-005 | Security managers require Team+ | Upgrade plan or remove security_managers |

---

## Debug Mode

### Enable Terraform Debug Logging

```bash
# Full debug
export TF_LOG=DEBUG
terraform plan

# Provider-specific debug
export TF_LOG_PROVIDER=DEBUG
export TF_LOG_CORE=INFO
terraform plan

# Save to file
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform plan
```

### Enable GitHub Provider Debug

```hcl
provider "github" {
  owner = "my-org"

  # Uncomment for debugging
  # write_delay_ms = 1000  # Add delay between writes
  # read_delay_ms  = 500   # Add delay between reads
}
```

### Inspect State

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show 'module.github.github_repository.repo["my-repo"]'

# Export state
terraform state pull > state.json

# Search state
jq '.resources[] | select(.type=="github_repository")' state.json
```

---

## Getting Help

### Before Opening an Issue

1. **Check documentation**:
   - [README.md](README.md) - Module overview
   - [SECURITY.md](SECURITY.md) - Authentication and security
   - [docs/PERFORMANCE.md](docs/PERFORMANCE.md) - Performance optimization
   - [docs/ERROR_CODES.md](docs/ERROR_CODES.md) - Error reference

2. **Search existing issues**:
   ```
   https://github.com/YOUR_USERNAME/terraform-github-governance/issues
   ```

3. **Enable debug logging**:
   ```bash
   export TF_LOG=DEBUG
   terraform plan 2>&1 | tee debug.log
   ```

### Opening an Issue

Include:

1. **Terraform version**:
   ```bash
   terraform version
   ```

2. **Provider version**:
   ```bash
   terraform providers
   ```

3. **Module version**:
   ```hcl
   module "github" {
     source  = "vmvarela/governance/github"
     version = "1.x.x"  # Include this
   }
   ```

4. **Minimal reproduction**:
   ```hcl
   # Simplified config that reproduces the issue
   module "github" {
     source = "..."

     mode = "organization"
     name = "test-org"

     repositories = {
       "test" = {}  # Minimal config
     }
   }
   ```

5. **Error output**:
   ```
   Paste full error message (sanitize secrets!)
   ```

6. **Expected vs actual behavior**

7. **Debug logs** (if relevant):
   ```
   Attach debug.log (sanitize secrets!)
   ```

---

## Community Resources

- **GitHub Discussions**: Q&A, ideas, show & tell
- **GitHub Issues**: Bug reports, feature requests
- **HashiCorp Forum**: Terraform-specific questions
- **Discord/Slack**: Real-time community help (if available)

---

**Last Updated**: November 12, 2025
**Version**: 1.0.0
