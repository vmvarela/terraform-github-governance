# Performance Optimization Guide

This guide provides best practices and strategies for optimizing the performance of the terraform-github-governance module when managing large GitHub organizations.

## Table of Contents

- [Overview](#overview)
- [Performance Considerations](#performance-considerations)
- [Large Organization Strategies](#large-organization-strategies)
- [State Management](#state-management)
- [Targeted Operations](#targeted-operations)
- [Parallel Execution](#parallel-execution)
- [Resource Limits](#resource-limits)
- [Monitoring and Metrics](#monitoring-and-metrics)
- [Best Practices Summary](#best-practices-summary)

---

## Overview

### When to Use This Guide

This guide is relevant when managing:
- ✅ Organizations with 50+ repositories
- ✅ Multiple runner groups with complex access patterns
- ✅ Large teams with many members (100+)
- ✅ Frequent Terraform operations (daily/hourly)
- ✅ CI/CD pipelines running Terraform

### Performance Factors

The module's performance is primarily affected by:

1. **GitHub API Rate Limits**
   - 5,000 requests/hour for authenticated users
   - Lower limits for certain endpoints

2. **Number of Resources**
   - Repositories, teams, runner groups, secrets

3. **State File Size**
   - Grows with resource count
   - Remote state reduces local overhead

4. **Network Latency**
   - API call overhead increases with resource count

---

## Performance Considerations

### API Rate Limiting

**Understanding GitHub Rate Limits:**

```bash
# Check your current rate limit
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/rate_limit
```

**Module Operations vs Rate Limit:**

| Operation | Typical API Calls | Rate Limit Impact |
|-----------|------------------|-------------------|
| Create 10 repos | ~50-100 | Low |
| Create 50 repos | ~250-500 | Medium |
| Create 100 repos | ~500-1000 | High |
| Full org refresh | ~1000+ | Very High |

**Mitigation Strategies:**

1. **Use Project Mode for repo groups:**
   ```hcl
   # Instead of 100 separate module calls
   module "github_org" {
     source = "path/to/module"
     mode   = "project"

     repositories = {
       for i in range(100) : "repo-${i}" => {
         description = "Repository ${i}"
       }
     }
   }
   ```

2. **Implement retry logic in CI/CD:**
   ```bash
   # In your pipeline
   terraform apply -auto-approve || {
     sleep 60
     terraform apply -auto-approve
   }
   ```

3. **Stagger operations across time:**
   ```hcl
   # Use workspace separation for different repo groups
   terraform workspace select prod-batch-1
   terraform apply

   # Wait for rate limit reset
   terraform workspace select prod-batch-2
   terraform apply
   ```

---

## Large Organization Strategies

### 1. Workspace Segmentation

**Split large configurations into multiple workspaces:**

```bash
# Structure
terraform-github-governance/
├── workspaces/
│   ├── core-infrastructure/     # Critical repos (5-10)
│   ├── product-team-a/          # Team A repos (20-30)
│   ├── product-team-b/          # Team B repos (20-30)
│   └── archived/                # Archived repos
```

**Benefits:**
- ✅ Isolated state files (smaller, faster)
- ✅ Independent apply operations
- ✅ Parallel execution possible
- ✅ Reduced blast radius
- ✅ Team-specific ownership

**Example Configuration:**

```hcl
# workspaces/product-team-a/main.tf
module "team_a_repos" {
  source = "../../"
  mode   = "project"

  repositories = {
    # Only Team A repositories
    "team-a-api"      = { ... }
    "team-a-frontend" = { ... }
    # ... 20 more repos
  }

  runner_groups = {
    "team-a-runners" = {
      visibility   = "selected"
      repositories = keys(var.repositories)
    }
  }
}
```

### 2. Hierarchical Module Structure

**Use nested modules for organization:**

```hcl
# Root module - organization-wide settings
module "org_settings" {
  source = "./modules/org-settings"

  organization = var.organization
  webhooks     = var.org_webhooks
  rulesets     = var.org_rulesets
}

# Team-specific modules
module "team_repositories" {
  source   = "./modules/team-repos"
  for_each = var.teams

  team_name    = each.key
  repositories = each.value.repositories
  runner_group = each.value.runner_group
}
```

### 3. Repository Grouping Strategy

**Group repositories by:**

1. **Lifecycle stage:**
   - Active development
   - Production/stable
   - Maintenance mode
   - Archived

2. **Team ownership:**
   - Platform team
   - Product teams
   - Infrastructure team

3. **Update frequency:**
   - Frequently updated (daily)
   - Occasionally updated (weekly/monthly)
   - Rarely updated (quarterly)

**Example grouping:**

```hcl
locals {
  # High-frequency updates
  active_repos = {
    for k, v in var.all_repositories :
    k => v if contains(["active", "development"], v.lifecycle)
  }

  # Low-frequency updates
  stable_repos = {
    for k, v in var.all_repositories :
    k => v if contains(["stable", "maintenance"], v.lifecycle)
  }
}

# Separate module calls
module "active" {
  source       = "./path/to/module"
  repositories = local.active_repos
}

module "stable" {
  source       = "./path/to/module"
  repositories = local.stable_repos
}
```

---

## State Management

### Remote State Configuration

**Always use remote state for large organizations:**

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-github-org"
    key            = "github/org-governance.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

**Benefits:**
- ✅ Team collaboration
- ✅ State locking
- ✅ State versioning
- ✅ Reduced local disk usage

### State File Optimization

**1. State Migration for Large Configs:**

```bash
# Before migration: 1 large state (1000 resources)
# After migration: 10 smaller states (100 resources each)

# Export resources from original state
terraform state pull > full-state.json

# Create new workspaces and import
terraform workspace new team-a
terraform import 'module.repos["repo-1"]' repo-1
# ... repeat for each resource

# Remove from original state
terraform state rm 'module.repos["repo-1"]'
```

**2. Selective State Refresh:**

```bash
# Refresh only specific resources
terraform refresh -target=module.critical_repos

# Skip unnecessary refreshes
terraform plan -refresh=false
terraform apply -refresh=false
```

**3. State File Size Monitoring:**

```bash
# Check state file size
terraform state pull | wc -c

# Identify largest resources
terraform state pull | jq '.resources | group_by(.type) |
  map({type: .[0].type, count: length}) | sort_by(.count) | reverse'
```

---

## Targeted Operations

### Resource Targeting

**Apply changes to specific resources:**

```bash
# Target single repository
terraform apply -target='module.github.github_repository.repositories["api"]'

# Target runner groups only
terraform apply -target='module.github.github_actions_organization_permissions.this'
terraform apply -target='module.github.github_actions_runner_group.runner_groups'

# Target multiple resources with pattern
terraform apply -target='module.github.github_repository.repositories["prod-*"]'
```

### Change Batching

**Group related changes:**

```hcl
# variables.tf - use feature flags
variable "enable_webhooks" {
  type    = bool
  default = false
}

variable "enable_runner_groups" {
  type    = bool
  default = false
}

# main.tf - conditional resources
resource "github_repository_webhook" "webhooks" {
  for_each = var.enable_webhooks ? var.webhooks : {}
  # ...
}
```

**Rollout strategy:**

```bash
# Phase 1: Create repositories only
terraform apply -var="enable_webhooks=false" -var="enable_runner_groups=false"

# Phase 2: Add webhooks
terraform apply -var="enable_webhooks=true" -var="enable_runner_groups=false"

# Phase 3: Add runner groups
terraform apply -var="enable_webhooks=true" -var="enable_runner_groups=true"
```

---

## Parallel Execution

### Terraform Parallelism

**Adjust parallelism based on rate limits:**

```bash
# Default: -parallelism=10
terraform apply

# Reduced parallelism for rate limit compliance
terraform apply -parallelism=5

# Increased parallelism for small batches
terraform apply -parallelism=20
```

**Optimal parallelism settings:**

| Repositories | Recommended Parallelism | API Calls/Min |
|--------------|------------------------|---------------|
| 1-10         | 10 (default)           | ~50-100       |
| 11-50        | 5-8                    | ~25-80        |
| 51-100       | 3-5                    | ~15-50        |
| 100+         | 2-3                    | ~10-30        |

### CI/CD Pipeline Optimization

**Parallel workspace execution:**

```yaml
# GitHub Actions example
jobs:
  apply-core:
    runs-on: ubuntu-latest
    steps:
      - uses: hashicorp/setup-terraform@v2
      - run: |
          cd workspaces/core-infrastructure
          terraform init
          terraform apply -auto-approve

  apply-teams:
    needs: apply-core
    strategy:
      matrix:
        team: [team-a, team-b, team-c, team-d]
      max-parallel: 2  # Prevent rate limiting
    runs-on: ubuntu-latest
    steps:
      - uses: hashicorp/setup-terraform@v2
      - run: |
          cd workspaces/${{ matrix.team }}
          terraform init
          terraform apply -auto-approve
```

---

## Resource Limits

### GitHub API Constraints

**Per-resource limits:**

| Resource Type | GitHub Limit | Recommendation |
|--------------|--------------|----------------|
| Repositories per org | Unlimited | Batch by 50-100 |
| Teams per org | 5,000 | No special handling needed |
| Team members | 5,000 per team | Split large teams |
| Webhooks per org | 20 | Use selectively |
| Secrets per org | 1,000 | Archive unused |
| Runner groups | 1,000 | Organize by team/project |

### Module Limits and Recommendations

**Tested limits:**

- ✅ Up to 200 repositories per module instance
- ✅ Up to 50 runner groups
- ✅ Up to 100 webhooks (org + repos combined)
- ✅ Up to 500 secrets (org + repos combined)

**Soft limits (recommended):**

- 🎯 50-100 repositories per workspace (optimal)
- 🎯 10-20 runner groups per workspace
- 🎯 25-50 webhooks total
- 🎯 100-200 secrets total

**When to split:**

```hcl
# ❌ Too large - prone to timeouts and errors
module "all_repos" {
  source = "./path/to/module"

  repositories = {
    # 500 repositories defined here
  }
}

# ✅ Better - split by team
module "platform_team" {
  source       = "./path/to/module"
  repositories = local.platform_repos  # ~75 repos
}

module "product_team" {
  source       = "./path/to/module"
  repositories = local.product_repos   # ~80 repos
}
```

---

## Monitoring and Metrics

### Operation Timing

**Track Terraform operation duration:**

```bash
# Enable timing details
export TF_LOG=INFO
export TF_LOG_PATH=./terraform.log

# Run operation
time terraform apply -auto-approve

# Analyze timing
grep "duration" terraform.log | sort -n -k3
```

### Resource Count Monitoring

**Track resources over time:**

```bash
# Count resources in state
terraform state list | wc -l

# Count by type
terraform state list | cut -d. -f1 | sort | uniq -c

# Track growth
echo "$(date),$(terraform state list | wc -l)" >> resource-count.csv
```

### Health Checks

**Pre-flight checks before apply:**

```bash
#!/bin/bash
# preflight.sh

echo "🔍 Performing pre-flight checks..."

# Check rate limit
REMAINING=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/rate_limit | jq -r '.rate.remaining')
echo "📊 API rate limit remaining: $REMAINING"

if [ "$REMAINING" -lt 1000 ]; then
  echo "⚠️  Warning: Low rate limit. Consider waiting."
  exit 1
fi

# Check state file size
STATE_SIZE=$(terraform state pull | wc -c)
echo "📦 State file size: $STATE_SIZE bytes"

if [ "$STATE_SIZE" -gt 10000000 ]; then
  echo "⚠️  Warning: Large state file. Consider splitting."
fi

# Count planned changes
CHANGES=$(terraform plan -no-color 2>&1 | grep "Plan:" | grep -oE '[0-9]+' | head -1)
echo "📝 Planned changes: $CHANGES resources"

if [ "$CHANGES" -gt 100 ]; then
  echo "⚠️  Warning: Large changeset. Consider batching."
fi

echo "✅ Pre-flight checks complete"
```

### Performance Metrics Dashboard

**Example metrics to track:**

```hcl
# outputs.tf - export metrics
output "performance_metrics" {
  value = {
    total_repositories   = length(github_repository.repositories)
    total_runner_groups  = length(github_actions_runner_group.runner_groups)
    total_webhooks       = length(github_organization_webhook.webhooks) + sum([
      for repo, hooks in github_repository_webhook.repository_webhooks : length(hooks)
    ])
    state_resources      = data.external.state_count.result.count
    last_apply_duration  = timestamp()
  }
}

# Query in CI/CD or monitoring
terraform output -json performance_metrics | jq .
```

---

## Best Practices Summary

### Do's ✅

1. **Use remote state** for collaboration and state locking
2. **Split large organizations** into multiple workspaces (50-100 repos each)
3. **Monitor rate limits** before large operations
4. **Use targeted applies** for specific resource changes
5. **Implement feature flags** for gradual rollouts
6. **Track resource counts** over time
7. **Adjust parallelism** based on organization size
8. **Use project mode** for grouping related repositories
9. **Archive unused resources** to reduce state size
10. **Document workspace structure** for team collaboration

### Don'ts ❌

1. **Don't manage 500+ repos** in a single workspace
2. **Don't ignore rate limits** - implement retries and backoff
3. **Don't refresh unnecessarily** - use `-refresh=false` when appropriate
4. **Don't apply all changes at once** - batch and phase rollouts
5. **Don't keep large state files locally** - use remote state
6. **Don't over-parallelize** - respect API rate limits
7. **Don't skip pre-flight checks** in CI/CD
8. **Don't mix unrelated resources** in the same workspace
9. **Don't ignore performance warnings** in logs
10. **Don't forget to clean up** archived/deleted resources from state

### Performance Optimization Checklist

Before deploying to production:

- [ ] Remote state configured with locking
- [ ] Workspace strategy defined and documented
- [ ] Repository grouping implemented
- [ ] Rate limit monitoring in place
- [ ] CI/CD pipeline uses appropriate parallelism
- [ ] Pre-flight checks implemented
- [ ] Resource count tracking configured
- [ ] Targeted apply strategy documented
- [ ] Team trained on performance best practices
- [ ] Rollback plan documented

---

## Additional Resources

- [GitHub API Rate Limits](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#rate-limiting)
- [Terraform Performance](https://www.terraform.io/docs/cloud/run/install-software.html#terraform-performance)
- [Managing Large Terraform Codebases](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Module Testing Guide](./TESTING.md)
- [Error Code Reference](./ERROR_CODES.md)

---

**Last Updated:** 2025-11-10
**Module Version:** 1.0.0
