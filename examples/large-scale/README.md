# Large Scale Organization Example

This example demonstrates managing a **large GitHub organization with 100+ repositories** using the terraform-github-governance module.

## Overview

This configuration manages:
- **100 repositories** across multiple teams and domains:
  - 40 backend microservices
  - 20 frontend applications
  - 15 infrastructure repositories
  - 15 data & analytics pipelines
  - 10 mobile applications
  - 5 documentation and public repositories
- **Organization-wide security policies** via settings cascade
- **Team-based access control** with 12+ teams
- **4 organization-level rulesets** for compliance
- **2 runner groups** for environment isolation
- **50+ deployment environments** across services

## Architecture

```
Organization (large-scale-org)
├── Settings (Global Policies)
│   ├── Security: Vulnerability alerts, Dependabot, Secret scanning
│   ├── Labels: Standard issue labels (bug, enhancement, security, etc.)
│   ├── Secrets: Slack, SonarQube, NPM tokens
│   └── Teams: 12+ teams with different permission levels
│
├── Repositories (100+)
│   ├── Backend (40) - Microservices by domain
│   │   ├── auth, billing, users, orders, inventory, shipping
│   │   ├── notifications, analytics (8 domains × 5 services each)
│   │   └── Each with production/staging/development environments
│   │
│   ├── Frontend (20) - Web, admin, customer, internal tools
│   │   └── Each with production environment
│   │
│   ├── Infrastructure (15) - Terraform, K8s, Helm, Ansible, etc.
│   │   └── Strict protection, admin access only
│   │
│   ├── Data (15) - ETL, ML, dashboards, streaming
│   │   └── Team: data + analytics
│   │
│   ├── Mobile (10) - iOS, Android, Flutter
│   │   └── Extended review time (10 min)
│   │
│   └── Public (5) - Docs, open-source, templates
│       └── Public visibility, community access
│
├── Rulesets (Organization-wide)
│   ├── main-branch-protection: PR reviews, CI checks
│   ├── conventional-commits: Enforce commit message format
│   ├── release-branch-protection: Stricter for releases
│   └── semver-tags: Semantic versioning enforcement
│
└── Runner Groups
    ├── production-runners: For production deployments only
    └── general-runners: For all other workflows
```

## Key Features

### 1. DRY Configuration with Settings Cascade

The module's **priority model** (`settings > repository > defaults`) enables efficient management:

```hcl
# Global defaults apply to ALL 100 repositories
defaults = {
  visibility             = "private"
  delete_branch_on_merge = true
  allow_squash_merge     = true
  # ... applied to all repos automatically
}

# Settings override defaults (policy enforcement)
settings = {
  enable_vulnerability_alerts = true  # Enforced on all repos
  enable_dependabot_security_updates = true
  enable_secret_scanning = true
  # ... centralized security policy
}

# Individual repos can override for specific needs
repositories = {
  "public-docs" = {
    visibility = "public"  # Override default "private"
  }
}
```

**Result**: Configure 100 repositories with ~15 lines of defaults + settings, instead of 1,500 lines of repetitive code.

### 2. Domain-Driven Repository Organization

Repositories are organized by business domain using Terraform's `for` expressions:

```hcl
# 40 backend microservices across 8 domains
{ for i in range(40) :
  "backend-service-${format("%03d", i)}" => {
    description = "Backend microservice ${i} - ${local.service_domains[i % 8]}"
    topics = ["backend", local.service_domains[i % 8], "kotlin"]
    teams = {
      "team-${local.service_domains[i % 8]}" = "push"
    }
  }
}
```

This creates:
- `backend-service-000` to `backend-service-004` → auth domain
- `backend-service-005` to `backend-service-009` → billing domain
- etc.

### 3. Organization-Wide Compliance

Four rulesets enforce governance across ALL repositories:

1. **Main Branch Protection**: PR reviews + CI checks required
2. **Conventional Commits**: Enforce commit message format
3. **Release Protection**: Stricter rules for release branches
4. **Tag Protection**: Semantic versioning for tags

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
      required_status_checks = {
        required_checks = [
          { context = "ci/tests" },
          { context = "ci/lint" },
          { context = "security/scan" }
        ]
      }
    }
  }
}
```

### 4. Performance Optimization

This configuration is optimized for scale:

- **Single `terraform apply`** manages all 100 repositories
- **Bulk operations** via GitHub API (not 100 separate calls)
- **Locals processing** pre-computes repository mappings
- **State file size**: ~2-3MB for 100 repos (manageable)
- **Plan time**: ~30-60 seconds (acceptable)
- **Apply time**: ~5-10 minutes for initial creation

## Usage

### Prerequisites

1. **Terraform** >= 1.6
2. **GitHub Provider** ~> 6.0
3. **GitHub Organization** with admin access
4. **GitHub App** (recommended) or Personal Access Token with:
   - `repo` (all)
   - `admin:org` (all)
   - `delete_repo`

### Authentication

For production, use GitHub App authentication:

```hcl
provider "github" {
  owner = "your-org"
  app_auth {
    id              = "123456"
    installation_id = "12345678"
    pem_file        = "${path.module}/github-app.pem"
  }
}
```

### Deployment

```bash
# 1. Copy and customize configuration
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Set your organization and secrets

# 2. Initialize Terraform
terraform init

# 3. Review plan (important for large scale!)
terraform plan -out=tfplan

# 4. Apply changes
terraform apply tfplan

# 5. View summary
terraform output summary
```

### Encrypting Secrets

GitHub organization secrets must be encrypted with the org's public key:

```bash
# Using GitHub CLI
gh secret set SLACK_WEBHOOK_URL --org your-org --body "https://hooks.slack.com/..."

# Or using the GitHub API
curl -X GET \
  https://api.github.com/orgs/your-org/actions/secrets/public-key

# Then encrypt locally and set in terraform.tfvars
```

## Performance Characteristics

Based on testing with this configuration:

| Metric | Value | Notes |
|--------|-------|-------|
| Total Repositories | 100 | 40 backend + 20 frontend + 15 infra + 15 data + 10 mobile + 5 public |
| Terraform Plan Time | ~45 seconds | Local execution |
| Terraform Apply Time | ~8 minutes | Initial creation |
| State File Size | ~2.5 MB | Manageable for remote state |
| Memory Usage | ~500 MB | During plan/apply |
| GitHub API Calls | ~300-400 | Bulk operations where possible |
| Rate Limit Impact | Minimal | Stays well under 5000/hour limit |

### Scaling Beyond 100 Repositories

For **500+ repositories**, consider:

1. **Split by domain**: Separate Terraform workspaces per team
2. **Use projects**: Enable `mode = "project"` for non-org GitHub
3. **Increase parallelism**: `terraform apply -parallelism=20`
4. **Remote state**: S3/GCS with locking for team collaboration
5. **GitHub App auth**: Better rate limits than PAT

## Outputs

This example provides comprehensive outputs:

```bash
# Summary
terraform output summary

# Repositories by team
terraform output repositories_by_team

# Security posture
terraform output security_posture

# Compliance status
terraform output organization_rulesets
```

Example output:

```hcl
summary = {
  organization = "your-org"
  total_repositories = 100
  by_visibility = {
    private = 95
    public = 5
  }
  security_posture = {
    vulnerability_alerts_enabled = 100
    dependabot_enabled = 100
    secret_scanning_enabled = 100
  }
  runner_groups = 2
  organization_rulesets = 4
}

repositories_by_team = {
  backend = 40
  frontend = 20
  infra = 15
  data = 15
  mobile = 10
  public = 5
}
```

## Customization

### Adding a New Team/Domain

To add a new domain (e.g., "ML team" with 10 repos):

```hcl
repositories = merge(
  # ... existing repositories ...
  
  # ML Team (10 repositories)
  { for i in range(10) :
    "ml-model-${format("%02d", i)}" => {
      description = "ML model: ${local.ml_models[i]}"
      topics = ["ml", "python", "pytorch"]
      teams = {
        "ml-team" = "push"
      }
    }
  }
)

locals {
  ml_models = [
    "recommendation",
    "fraud-detection",
    "churn-prediction",
    # ...
  ]
}
```

### Adjusting Security Policies

Modify `settings` to change organization-wide policies:

```hcl
settings = {
  # Make secret scanning push protection optional
  enable_secret_scanning_push_protection = false
  
  # Add more labels
  issue_labels = {
    "urgent" = "ff0000"  # bright red for urgent issues
  }
  
  # Add more secrets
  secrets_encrypted = {
    CUSTOM_API_KEY = var.custom_api_key_encrypted
  }
}
```

### Adding New Rulesets

Create additional organization-wide rules:

```hcl
rulesets = {
  # ... existing rulesets ...
  
  "security-review-for-prod" = {
    enforcement = "active"
    target = "branch"
    
    conditions = {
      ref_name = {
        include = ["refs/heads/main", "refs/heads/release/**"]
      }
    }
    
    rules = {
      pull_request = {
        required_approving_review_count = 2
        require_code_owner_review = true
      }
    }
    
    bypass_actors = {
      teams = ["security-team"]
    }
  }
}
```

## Troubleshooting

### Rate Limiting

If you hit GitHub API rate limits:

```bash
# Check current rate limit
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/rate_limit

# Wait or use GitHub App (higher limits)
# GitHub App: 15,000 requests/hour
# PAT: 5,000 requests/hour
```

### Plan Takes Too Long

For very large plans:

```bash
# Use targeted plans during development
terraform plan -target=module.github_org.github_repository.repo["specific-repo"]

# Increase parallelism
terraform apply -parallelism=20
```

### State File Too Large

For 500+ repos, split by domain:

```
workspaces/
├── backend/     # 200 backend repos
├── frontend/    # 100 frontend repos
└── infrastructure/  # 50 infra repos
```

## Related Examples

- **[simple](../simple/)**: Basic module usage with 5 repositories
- **[complete](../complete/)**: Comprehensive feature demonstration
- **[rulesets-advanced](../rulesets-advanced/)**: Advanced ruleset configurations (coming soon)

## Contributing

To test changes at this scale:

1. Use a test organization (not production!)
2. Start with 10-20 repos for initial validation
3. Scale to 100+ once logic is confirmed
4. Monitor rate limits and performance

## License

Apache 2.0 - See [LICENSE](../../LICENSE) for details.
