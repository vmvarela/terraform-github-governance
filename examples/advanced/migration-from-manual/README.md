# Migration from Manual GitHub Management to IaC

This advanced example demonstrates how to migrate an existing GitHub organization from manual configuration to Infrastructure as Code using this module.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Migration Strategy](#migration-strategy)
- [Phase 1: Discovery](#phase-1-discovery)
- [Phase 2: Import Existing Resources](#phase-2-import-existing-resources)
- [Phase 3: Gradual Migration](#phase-3-gradual-migration)
- [Phase 4: Full Automation](#phase-4-full-automation)
- [Rollback Strategy](#rollback-strategy)

## Overview

Migrating from manual GitHub management to IaC requires careful planning to avoid:
- 🚫 Accidental repository deletions
- 🚫 Loss of configuration (webhooks, secrets, branch protections)
- 🚫 Disruption to development workflows
- 🚫 Breaking CI/CD pipelines

**Migration Timeline:** 2-4 weeks (depending on org size)

## Prerequisites

### 1. GitHub Token with Required Permissions

```bash
# Required scopes for migration:
# - repo (full control)
# - admin:org (full control)
# - admin:org_hook (full control)
# - delete_repo (for cleanup, optional)

export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxx"
export GITHUB_OWNER="my-organization"
```

### 2. Backup Current Configuration

```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login

# Create backup directory
mkdir -p github-backup-$(date +%Y%m%d)
cd github-backup-$(date +%Y%m%d)

# Export all repositories
gh repo list $GITHUB_OWNER --limit 1000 --json name,description,visibility,isPrivate,isArchived > repositories.json

# Export organization settings
gh api /orgs/$GITHUB_OWNER > organization.json

# Export webhooks
gh api /orgs/$GITHUB_OWNER/hooks > webhooks.json
```

### 3. Install Terraform Import Tools

```bash
# Install terraformer (optional, helps with import)
brew install terraformer

# Install tf-import-gen (custom script)
curl -o tf-import-gen.sh https://raw.githubusercontent.com/your-repo/tf-import-gen/main/import.sh
chmod +x tf-import-gen.sh
```

## Migration Strategy

### Four-Phase Approach

```
┌─────────────────────────────────────────────────────────────┐
│  PHASE 1: DISCOVERY (Week 1)                                │
│  • Audit existing resources                                 │
│  • Document current state                                   │
│  • Identify critical vs non-critical repos                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  PHASE 2: IMPORT (Week 1-2)                                 │
│  • Start with non-critical repos (sandbox, archived)        │
│  • Import to Terraform state                                │
│  • Verify no drift                                          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  PHASE 3: GRADUAL MIGRATION (Week 2-3)                      │
│  • Import critical repos (production, infrastructure)       │
│  • Migrate team-by-team                                     │
│  • Enable lifecycle protections                             │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│  PHASE 4: FULL AUTOMATION (Week 4)                          │
│  • All repos managed by Terraform                           │
│  • CI/CD pipeline for changes                               │
│  • Self-service via Pull Requests                           │
└─────────────────────────────────────────────────────────────┘
```

## Phase 1: Discovery

### Step 1.1: Audit Existing Resources

Create a discovery script to catalog all resources:

```bash
#!/bin/bash
# discover-github-resources.sh

GITHUB_ORG="my-organization"
OUTPUT_DIR="discovery-output"

mkdir -p $OUTPUT_DIR

echo "🔍 Discovering GitHub resources for: $GITHUB_ORG"

# Repositories
echo "📦 Fetching repositories..."
gh repo list $GITHUB_ORG --limit 1000 --json name,description,visibility,isPrivate,isArchived,defaultBranch > $OUTPUT_DIR/repositories.json

# Count by type
echo "📊 Repository Statistics:"
jq -r '.[] | select(.isArchived == false) | .visibility' $OUTPUT_DIR/repositories.json | sort | uniq -c

# Teams
echo "👥 Fetching teams..."
gh api "/orgs/$GITHUB_ORG/teams?per_page=100" > $OUTPUT_DIR/teams.json

# Webhooks
echo "🔗 Fetching organization webhooks..."
gh api "/orgs/$GITHUB_ORG/hooks" > $OUTPUT_DIR/webhooks.json

# Runner groups
echo "🏃 Fetching runner groups..."
gh api "/orgs/$GITHUB_ORG/actions/runner-groups" > $OUTPUT_DIR/runner-groups.json

echo "✅ Discovery complete! Results in: $OUTPUT_DIR"
```

### Step 1.2: Categorize Repositories

```bash
# categorize-repos.sh
# Categorizes repos by criticality for phased migration

jq -r '.[] | select(.isArchived == false) |
  if .name | test("prod|production|main|core") then
    "CRITICAL: " + .name
  elif .name | test("test|sandbox|demo|poc") then
    "NON-CRITICAL: " + .name
  else
    "NORMAL: " + .name
  end' discovery-output/repositories.json > categorized-repos.txt
```

## Phase 2: Import Existing Resources

### Step 2.1: Start with Non-Critical Repos

Create initial Terraform configuration:

```hcl
# main.tf (Phase 2 - Initial)

terraform {
  required_version = ">= 1.6"

  # Use remote backend for team collaboration
  backend "s3" {
    bucket = "my-org-terraform-state"
    key    = "github/terraform.tfstate"
    region = "us-east-1"
  }
}

module "github_governance" {
  source = "../../.."  # or "vmvarela/governance/github"

  mode       = "organization"
  name       = "my-organization"
  github_org = "my-organization"

  # PHASE 2: Start with NON-CRITICAL repos only
  repositories = {
    # Archived repos (safe to test)
    "legacy-project" = {
      description = "Legacy project (archived)"
      visibility  = "private"
      archived    = true
    }

    # Sandbox repos (non-critical)
    "sandbox-test" = {
      description = "Testing sandbox"
      visibility  = "private"
      has_issues  = true
    }
  }

  # Organization-wide defaults
  defaults = {
    visibility                = "private"
    has_issues                = true
    delete_branch_on_merge    = true
    vulnerability_alerts      = true
  }
}
```

### Step 2.2: Import Existing Repos to State

```bash
# import-repos.sh
# Imports existing GitHub repos to Terraform state

REPOS=("legacy-project" "sandbox-test")

for repo in "${REPOS[@]}"; do
  echo "📥 Importing repository: $repo"

  # Import repository
  terraform import \
    'module.github_governance.github_repository.repo["'$repo'"]' \
    "$repo"

  # Import default branch
  terraform import \
    'module.github_governance.github_branch_default.default["'$repo'"]' \
    "$repo"

  echo "✅ Imported: $repo"
done

# Verify no changes needed
terraform plan
```

### Step 2.3: Verify No Drift

```bash
# Run plan to ensure state matches reality
terraform plan -detailed-exitcode

# Exit codes:
# 0 = No changes
# 1 = Error
# 2 = Changes detected (EXPECTED in first run)

# After adjusting config to match reality:
terraform plan -detailed-exitcode
# Should return 0 (no changes)
```

## Phase 3: Gradual Migration

### Step 3.1: Migrate Production Repos (Carefully!)

```hcl
# main.tf (Phase 3 - Add Production Repos)

module "github_governance" {
  source = "../../.."

  mode       = "organization"
  name       = "my-organization"
  github_org = "my-organization"

  repositories = {
    # Phase 2 repos (already imported)
    "legacy-project" = { ... }
    "sandbox-test"   = { ... }

    # Phase 3: Add CRITICAL production repos
    "backend-api" = {
      description = "Production Backend API"
      visibility  = "private"

      # ⚠️ IMPORTANT: Enable protections before import
      lifecycle {
        prevent_destroy = true  # Can't accidentally delete
      }

      # Branch protection
      branch_protections = [{
        pattern                         = "main"
        required_approving_review_count = 2
        require_code_owner_reviews      = true
        dismiss_stale_reviews           = true
        required_status_checks = [
          "ci/test",
          "ci/lint",
          "security/scan"
        ]
      }]

      # Environments
      environments = {
        production = {
          wait_timer            = 300  # 5 min delay
          reviewers            = ["ops-team"]
          deployment_branch_policy = {
            protected_branches     = true
            custom_branch_policies = false
          }
        }
      }

      # Secrets (use encrypted values)
      secrets_encrypted = {
        DATABASE_URL = "AQICAHh+..."  # Pre-encrypted with GitHub public key
        API_KEY      = "AQICAHh+..."
      }
    }

    "frontend-app" = {
      description = "Production Frontend Application"
      visibility  = "private"

      lifecycle {
        prevent_destroy = true
      }

      # Link to backend
      topics = ["frontend", "react", "production"]

      # Deploy key for automated deployments
      deploy_keys = [{
        title     = "Vercel Deploy"
        read_only = true
        key       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
      }]
    }
  }
}
```

### Step 3.2: Import Critical Repos

```bash
# import-critical-repos.sh

# CRITICAL: Take backup before import
terraform state pull > state-backup-$(date +%Y%m%d-%H%M%S).json

CRITICAL_REPOS=("backend-api" "frontend-app")

for repo in "${CRITICAL_REPOS[@]}"; do
  echo "⚠️  CRITICAL: Importing production repo: $repo"
  echo "Press ENTER to continue or Ctrl+C to abort..."
  read

  # Import repository
  terraform import \
    'module.github_governance.github_repository.repo["'$repo'"]' \
    "$repo"

  # Import branch protection
  terraform import \
    'module.github_governance.github_branch_protection.protected["'$repo'/main"]' \
    "$repo:main"

  # Import environments
  terraform import \
    'module.github_governance.github_repository_environment.env["'$repo'/production"]' \
    "$repo:production"

  echo "✅ Imported critical repo: $repo"

  # Verify no destructive changes
  terraform plan | grep -E "(destroy|replace)"
  if [ $? -eq 0 ]; then
    echo "❌ ABORT: Destructive changes detected!"
    exit 1
  fi
done
```

### Step 3.3: Team-by-Team Migration

```hcl
# Organize by team for gradual rollout

# Team 1: Platform Team (Week 2)
module "platform_team_repos" {
  source = "../../.."

  mode       = "project"
  name       = "platform"
  github_org = "my-organization"
  spec       = "platform-%s"  # Prefix: platform-*

  repositories = {
    "api"       = { ... }
    "worker"    = { ... }
    "scheduler" = { ... }
  }
}

# Team 2: Data Team (Week 3)
module "data_team_repos" {
  source = "../../.."

  mode       = "project"
  name       = "data"
  github_org = "my-organization"
  spec       = "data-%s"  # Prefix: data-*

  repositories = {
    "pipeline"   = { ... }
    "warehouse"  = { ... }
    "analytics"  = { ... }
  }
}
```

## Phase 4: Full Automation

### Step 4.1: CI/CD Pipeline for GitHub Changes

```yaml
# .github/workflows/terraform-github.yml

name: Terraform GitHub Governance

on:
  pull_request:
    paths:
      - 'terraform/github/**'
  push:
    branches:
      - main
    paths:
      - 'terraform/github/**'

jobs:
  plan:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'

    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0

      - name: Terraform Init
        run: terraform init
        working-directory: terraform/github

      - name: Terraform Plan
        id: plan
        run: terraform plan -no-color
        working-directory: terraform/github
        env:
          GITHUB_TOKEN: ${{ secrets.TF_GITHUB_TOKEN }}

      - name: Comment PR
        uses: actions/github-script@v7
        with:
          script: |
            const output = `#### Terraform Plan 📖
            \`\`\`
            ${{ steps.plan.outputs.stdout }}
            \`\`\`
            `;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })

  apply:
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0

      - name: Terraform Init
        run: terraform init
        working-directory: terraform/github

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: terraform/github
        env:
          GITHUB_TOKEN: ${{ secrets.TF_GITHUB_TOKEN }}
```

### Step 4.2: Self-Service via Pull Requests

Enable developers to request new repositories via PR:

```hcl
# terraform/github/repositories.tf

# Self-service template (copy this for new repos)
locals {
  # Template for new repositories
  repo_template = {
    visibility                = "private"
    has_issues                = true
    has_projects              = true
    has_wiki                  = false
    delete_branch_on_merge    = true
    vulnerability_alerts      = true

    branch_protections = [{
      pattern                         = "main"
      required_approving_review_count = 1
      required_status_checks          = ["ci/test"]
    }]
  }
}

module "github_governance" {
  source = "../../.."

  repositories = {
    # ==========================================
    # 📝 TO REQUEST A NEW REPO:
    # 1. Copy the template below
    # 2. Fill in your details
    # 3. Create a Pull Request
    # 4. Wait for approval and merge
    # ==========================================

    # Example: New service repository
    # "my-new-service" = merge(local.repo_template, {
    #   description = "My awesome new service"
    #   topics      = ["golang", "microservice"]
    # })

    # Existing repositories below:
    "backend-api" = { ... }
    "frontend-app" = { ... }
  }
}
```

## Rollback Strategy

### Emergency Rollback Procedure

If something goes wrong during migration:

```bash
# 1. Restore Terraform state from backup
aws s3 cp s3://my-org-terraform-state/github/terraform.tfstate.backup \
          s3://my-org-terraform-state/github/terraform.tfstate

# 2. Remove problematic resources from state (don't destroy)
terraform state rm 'module.github_governance.github_repository.repo["problematic-repo"]'

# 3. Verify state is clean
terraform state list

# 4. Re-run plan
terraform plan

# 5. If needed, manually revert GitHub changes via UI
# (Terraform won't touch removed resources)
```

### Disaster Recovery

```bash
# If state is completely lost:

# 1. Restore from daily backup
terraform state pull > current-state.json
aws s3 cp s3://backups/terraform/github/$(date +%Y%m%d).tfstate terraform.tfstate
terraform state push terraform.tfstate

# 2. If no backup, re-import everything
./scripts/reimport-all-repos.sh

# 3. Verify
terraform plan -detailed-exitcode
```

## Best Practices

### ✅ DO

- Start with non-critical repositories
- Take frequent state backups
- Use `prevent_destroy` on all production repos
- Test import process in sandbox first
- Communicate with teams before migrating their repos
- Keep manual GitHub access for emergencies
- Use remote state with locking

### ❌ DON'T

- Import all repos at once
- Skip the plan review
- Ignore drift warnings
- Delete resources from state without backup
- Remove `prevent_destroy` from production repos
- Deploy to production on Fridays 😅

## Troubleshooting

### Issue: "Resource already exists"

```bash
# Solution: Import existing resource first
terraform import 'module.github_governance.github_repository.repo["repo-name"]' "repo-name"
```

### Issue: "Plan shows unwanted changes"

```hcl
# Solution: Add to ignore_changes
lifecycle {
  ignore_changes = [
    topics,        # Modified via UI
    description,   # Updated by team
  ]
}
```

### Issue: "Secret import fails"

```bash
# Secrets can't be imported (encrypted)
# Solution: Remove from state and recreate
terraform state rm 'module.github_governance.github_actions_secret.repo["repo/SECRET"]'
terraform apply
```

## Success Metrics

Track your migration progress:

```bash
# Repositories under Terraform management
terraform state list | grep "github_repository.repo" | wc -l

# Total repositories in organization
gh repo list $GITHUB_ORG --limit 1000 | wc -l

# Migration percentage
echo "scale=2; ($(terraform state list | grep github_repository.repo | wc -l) / $(gh repo list $GITHUB_ORG --limit 1000 | wc -l)) * 100" | bc
```

Target: **100% of active repositories** under Terraform management by Week 4.

---

## Next Steps

After successful migration:

1. ✅ Set up automated drift detection
2. ✅ Enable self-service repo creation
3. ✅ Document onboarding process for new teams
4. ✅ Create runbooks for common operations
5. ✅ Schedule quarterly reviews of governance policies

**🎉 Congratulations on completing your migration to Infrastructure as Code!**
