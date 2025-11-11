# Multi-Region GitHub Enterprise Architecture

This advanced example demonstrates how to manage GitHub Enterprise across multiple regions/instances with centralized governance using this module.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Use Cases](#use-cases)
- [Implementation](#implementation)
- [Cross-Region Synchronization](#cross-region-synchronization)
- [Disaster Recovery](#disaster-recovery)
- [Monitoring & Observability](#monitoring--observability)

## Overview

Large enterprises often need to manage multiple GitHub instances across:
- 🌍 Geographic regions (GDPR, data sovereignty)
- 🏢 Business units (separate billing, compliance)
- 🔒 Security zones (public cloud, on-premise, air-gapped)

This example shows how to use this module with a multi-instance strategy.

## Architecture

### Deployment Topology

```
┌──────────────────────────────────────────────────────────────┐
│  CENTRAL GOVERNANCE (Terraform Cloud/Enterprise)             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Workspace: github-us-east                             │  │
│  │  ├── State: us-east-repos.tfstate                      │  │
│  │  └── Region: US (GitHub.com Enterprise)               │  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Workspace: github-eu-west                             │  │
│  │  ├── State: eu-west-repos.tfstate                      │  │
│  │  └── Region: EU (GitHub Enterprise Server - Frankfurt)│  │
│  └────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Workspace: github-apac                                │  │
│  │  ├── State: apac-repos.tfstate                         │  │
│  │  └── Region: APAC (GitHub Enterprise Server - Tokyo)  │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                              ↓
        ┌─────────────────────┬─────────────────────┐
        ↓                     ↓                     ↓
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  GITHUB.COM      │  │  GHES EU         │  │  GHES APAC       │
│  (Cloud - US)    │  │  (On-Premise)    │  │  (On-Premise)    │
│                  │  │                  │  │                  │
│  Org: acme-us    │  │  Org: acme-eu    │  │  Org: acme-apac  │
│  Teams: 50       │  │  Teams: 30       │  │  Teams: 20       │
│  Repos: 500      │  │  Repos: 200      │  │  Repos: 150      │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

## Use Cases

### Use Case 1: Geographic Data Sovereignty

**Scenario:** EU customer data must stay in EU data centers.

```hcl
# environments/eu-west/main.tf

module "github_eu" {
  source = "../../../"

  # Connect to EU GitHub Enterprise Server
  providers = {
    github = github.eu
  }

  mode       = "organization"
  name       = "acme-eu"
  github_org = "acme-eu"

  # EU-specific compliance repositories
  repositories = {
    "customer-portal-eu" = {
      description = "Customer Portal (EU) - GDPR Compliant"
      visibility  = "private"

      # GDPR compliance tags
      topics = ["gdpr", "eu-data", "customer-facing"]

      # Strict branch protection for compliance
      branch_protections = [{
        pattern                         = "main"
        required_approving_review_count = 2
        require_code_owner_reviews      = true
        required_status_checks = [
          "security/gdpr-compliance",
          "security/data-residency-check"
        ]
      }]

      # Audit logging
      webhooks = [{
        url          = "https://audit-log-eu.acme.com/github"
        content_type = "json"
        events       = ["push", "pull_request", "issues"]
      }]
    }

    "user-data-service-eu" = {
      description = "User Data Service - EU Only"
      visibility  = "private"

      # Force EU deployment only
      environments = {
        production = {
          deployment_branch_policy = {
            protected_branches     = true
            custom_branch_policies = false
          }

          # EU ops team approval required
          reviewers = ["eu-ops-team"]
        }
      }

      # Secrets stored in EU KMS
      secrets_encrypted = {
        DATABASE_URL = "encrypted_with_eu_kms..."
        EU_API_KEY   = "encrypted_with_eu_kms..."
      }
    }
  }

  # EU-wide security defaults
  defaults = {
    visibility                = "private"
    vulnerability_alerts      = true
    secret_scanning           = true
    secret_scanning_push_protection = true
  }

  # Organization-level secrets (EU region)
  secrets_encrypted = {
    EU_COMPLIANCE_TOKEN = "encrypted..."
    AUDIT_WEBHOOK_KEY   = "encrypted..."
  }
}

# Provider configuration for EU instance
provider "github" {
  alias = "eu"
  owner = "acme-eu"
  token = var.github_token_eu

  # GitHub Enterprise Server (EU)
  base_url = "https://github.acme-eu.com"
}
```

### Use Case 2: Multi-Business Unit Management

**Scenario:** Parent company with independent subsidiaries.

```hcl
# environments/multi-bu/main.tf

# Parent Company - Central Governance
module "github_parent" {
  source = "../../../"

  mode       = "organization"
  name       = "acme-corp"
  github_org = "acme-corp"

  # Shared infrastructure repos
  repositories = {
    "platform-core" = {
      description = "Shared platform services"
      visibility  = "internal"  # Visible to all BUs
      topics      = ["platform", "shared", "infrastructure"]
    }

    "security-policies" = {
      description = "Corporate security policies"
      visibility  = "internal"

      # All BUs can read, only security team can write
      collaborators = [
        { username = "security-team", permission = "maintain" }
      ]
    }
  }

  # Corporate-wide settings
  settings = {
    # All repos must have these minimum protections
    branch_protections = [{
      pattern                         = "main"
      required_approving_review_count = 1
      required_status_checks          = ["security/scan"]
    }]
  }
}

# Business Unit 1: Retail
module "github_retail" {
  source = "../../../"

  mode       = "project"
  name       = "retail"
  github_org = "acme-corp"
  spec       = "retail-%s"  # All repos prefixed with "retail-"

  repositories = {
    "ecommerce-api" = {
      description = "E-commerce API"
      visibility  = "private"
      topics      = ["retail", "ecommerce", "api"]
    }

    "inventory-system" = {
      description = "Inventory Management"
      visibility  = "private"
      topics      = ["retail", "inventory"]
    }
  }

  # Inherit parent settings + retail-specific
  defaults = merge(
    module.github_parent.defaults,
    {
      # Retail-specific defaults
      topics = ["retail"]
    }
  )
}

# Business Unit 2: Financial Services
module "github_finserv" {
  source = "../../../"

  mode       = "project"
  name       = "finserv"
  github_org = "acme-corp"
  spec       = "fin-%s"  # All repos prefixed with "fin-"

  repositories = {
    "payment-gateway" = {
      description = "Payment Processing Gateway"
      visibility  = "private"

      # PCI-DSS compliance
      topics = ["finserv", "pci-dss", "payment"]

      # Stricter protections for financial services
      branch_protections = [{
        pattern                         = "main"
        required_approving_review_count = 3  # More reviews
        require_code_owner_reviews      = true
        required_status_checks = [
          "security/pci-compliance",
          "security/vulnerability-scan",
          "tests/integration"
        ]
      }]
    }
  }

  # Financial services security standards
  defaults = {
    visibility                = "private"
    vulnerability_alerts      = true
    secret_scanning           = true
    secret_scanning_push_protection = true
    advanced_security         = true  # Required for finserv
  }
}
```

### Use Case 3: Air-Gapped Government Installation

**Scenario:** Classified government work requires air-gapped GitHub Enterprise.

```hcl
# environments/gov-airgap/main.tf

module "github_classified" {
  source = "../../../"

  providers = {
    github = github.classified
  }

  mode       = "organization"
  name       = "defense-classified"
  github_org = "defense-classified"

  # Classified repositories
  repositories = {
    "secure-comms-system" = {
      description = "Classified: Secure Communications System"
      visibility  = "private"

      # Maximum security settings
      branch_protections = [{
        pattern                         = "main"
        required_approving_review_count = 3
        require_code_owner_reviews      = true
        require_signed_commits          = true  # GPG required
        required_status_checks = [
          "security/clearance-check",
          "security/code-review",
          "security/static-analysis"
        ]
      }]

      # No external webhooks (air-gapped)
      webhooks = []

      # Deployment requires multiple approvals
      environments = {
        production = {
          wait_timer = 3600  # 1 hour delay
          reviewers  = [
            "clearance-level-5-team",
            "security-officer"
          ]

          # Only deploy from protected branches
          deployment_branch_policy = {
            protected_branches     = true
            custom_branch_policies = false
          }
        }
      }
    }
  }

  # Organization-level security
  rulesets = [{
    name        = "classified-security-baseline"
    target      = "branch"
    enforcement = "active"

    conditions = {
      ref_name = {
        include = ["refs/heads/main", "refs/heads/release/*"]
      }
    }

    rules = {
      required_signatures = true  # All commits must be GPG signed

      required_status_checks = {
        strict_required_status_checks_policy = true
        required_status_checks = [
          "security/clearance-verification",
          "security/vulnerability-scan",
          "compliance/nist-800-53"
        ]
      }
    }
  }]

  # Strict defaults
  defaults = {
    visibility                = "private"
    has_issues                = false  # Use internal ticketing
    has_wiki                  = false  # No wikis for classified
    vulnerability_alerts      = true
    secret_scanning           = true
    secret_scanning_push_protection = true
  }
}

# Air-gapped GitHub Enterprise Server
provider "github" {
  alias = "classified"
  owner = "defense-classified"
  token = var.github_token_classified

  # Internal network only
  base_url = "https://github.defense.local"
}
```

## Implementation

### Directory Structure

```
terraform/
├── modules/
│   └── github-governance/  # This module
│
├── environments/
│   ├── us-east/           # US East region
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   │
│   ├── eu-west/           # EU West region
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   │
│   └── apac/              # APAC region
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
│
└── shared/
    ├── policies.tf        # Shared security policies
    └── standards.tf       # Compliance standards
```

### Shared Configuration Module

```hcl
# shared/policies.tf

locals {
  # Standard security baseline for all regions
  security_baseline = {
    vulnerability_alerts      = true
    secret_scanning           = true
    secret_scanning_push_protection = true
    delete_branch_on_merge    = true

    branch_protections = [{
      pattern                         = "main"
      required_approving_review_count = 1
      required_status_checks          = ["ci/test"]
    }]
  }

  # Compliance levels
  compliance_levels = {
    standard = local.security_baseline

    high = merge(local.security_baseline, {
      branch_protections = [{
        pattern                         = "main"
        required_approving_review_count = 2
        require_code_owner_reviews      = true
        required_status_checks = [
          "security/sast",
          "security/dependency-check",
          "ci/test"
        ]
      }]
    })

    critical = merge(local.security_baseline, {
      branch_protections = [{
        pattern                         = "main"
        required_approving_review_count = 3
        require_code_owner_reviews      = true
        require_signed_commits          = true
        required_status_checks = [
          "security/sast",
          "security/dast",
          "security/compliance",
          "ci/test",
          "ci/integration"
        ]
      }]
    })
  }
}

output "security_baseline" {
  value = local.security_baseline
}

output "compliance_levels" {
  value = local.compliance_levels
}
```

### Using Shared Policies

```hcl
# environments/us-east/main.tf

# Import shared policies
module "shared_policies" {
  source = "../../shared"
}

module "github_us" {
  source = "../../../"

  mode       = "organization"
  name       = "acme-us"
  github_org = "acme-us"

  repositories = {
    # Standard compliance repo
    "website" = merge(
      module.shared_policies.compliance_levels.standard,
      {
        description = "Public website"
        visibility  = "public"
      }
    )

    # High compliance repo
    "api-gateway" = merge(
      module.shared_policies.compliance_levels.high,
      {
        description = "API Gateway"
        visibility  = "private"
      }
    )

    # Critical compliance repo
    "payment-processor" = merge(
      module.shared_policies.compliance_levels.critical,
      {
        description = "Payment Processing System"
        visibility  = "private"
        topics      = ["pci-dss", "payment", "critical"]
      }
    )
  }
}
```

## Cross-Region Synchronization

### Scenario: Mirror critical repos across regions for DR

```hcl
# environments/multi-region-mirror/main.tf

locals {
  # Critical repos that must exist in all regions
  critical_repos = {
    "platform-core" = {
      description = "Core platform services"
      visibility  = "private"
      topics      = ["platform", "critical", "multi-region"]
    }

    "auth-service" = {
      description = "Authentication service"
      visibility  = "private"
      topics      = ["auth", "critical", "multi-region"]
    }
  }
}

# US East (Primary)
module "github_us_primary" {
  source = "../../../"

  providers = {
    github = github.us
  }

  mode       = "organization"
  name       = "acme-us"
  github_org = "acme-us"

  repositories = local.critical_repos

  # Mark as primary region
  defaults = {
    topics = ["region:us-east", "primary"]
  }
}

# EU West (Mirror)
module "github_eu_mirror" {
  source = "../../../"

  providers = {
    github = github.eu
  }

  mode       = "organization"
  name       = "acme-eu"
  github_org = "acme-eu"

  repositories = local.critical_repos

  # Mark as mirror region
  defaults = {
    topics = ["region:eu-west", "mirror"]
  }
}

# Setup repo mirroring via GitHub Actions
resource "github_repository_file" "mirror_workflow_us" {
  for_each = local.critical_repos

  repository = "acme-us/${each.key}"
  file       = ".github/workflows/mirror-to-eu.yml"
  content    = templatefile("${path.module}/templates/mirror-workflow.yml", {
    target_org  = "acme-eu"
    target_repo = each.key
  })
}
```

### Mirror Workflow Template

```yaml
# templates/mirror-workflow.yml

name: Mirror to EU Region

on:
  push:
    branches:
      - main
      - 'release/**'
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  mirror:
    runs-on: ubuntu-latest
    steps:
      - name: Mirror repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history

      - name: Push to EU mirror
        env:
          EU_TOKEN: ${{ secrets.GITHUB_EU_TOKEN }}
        run: |
          git remote add eu https://$EU_TOKEN@github.acme-eu.com/${target_org}/${target_repo}.git
          git push eu --all --force
          git push eu --tags --force
```

## Disaster Recovery

### DR Strategy

```hcl
# environments/disaster-recovery/main.tf

module "github_dr_playbook" {
  source = "../../../"

  mode       = "organization"
  name       = "acme-dr"
  github_org = "acme-dr"

  repositories = {
    "dr-runbooks" = {
      description = "Disaster Recovery Runbooks"
      visibility  = "private"

      # DR documentation as code
      files = [
        {
          file    = "runbooks/github-outage.md"
          content = file("${path.module}/runbooks/github-outage.md")
        },
        {
          file    = "runbooks/region-failover.md"
          content = file("${path.module}/runbooks/region-failover.md")
        },
        {
          file    = "scripts/failover.sh"
          content = file("${path.module}/scripts/failover.sh")
        }
      ]
    }
  }
}
```

### Automated Failover Script

```bash
#!/bin/bash
# scripts/failover.sh
# Automated failover from primary to secondary region

set -e

PRIMARY_REGION="us-east"
SECONDARY_REGION="eu-west"
TERRAFORM_DIR="/opt/terraform/github"

echo "🚨 Initiating GitHub Enterprise failover..."
echo "Primary: $PRIMARY_REGION → Secondary: $SECONDARY_REGION"

# 1. Verify primary is down
echo "1️⃣ Verifying primary region status..."
if curl -f -s "https://github.acme-$PRIMARY_REGION.com/api/v3/meta" > /dev/null 2>&1; then
  echo "⚠️  Primary region is UP. Aborting failover."
  echo "Manual override: Set FORCE_FAILOVER=true"
  [ "$FORCE_FAILOVER" != "true" ] && exit 1
fi

# 2. Promote secondary to primary
echo "2️⃣ Promoting secondary region to primary..."
cd "$TERRAFORM_DIR/environments/$SECONDARY_REGION"

# Update DNS/load balancer
terraform apply -auto-approve \
  -var="is_primary=true" \
  -var="accept_read_write_traffic=true"

# 3. Update Terraform Cloud workspace variables
echo "3️⃣ Updating Terraform Cloud variables..."
tfe-cli workspace set-var \
  --name "github-$SECONDARY_REGION" \
  --key "TF_VAR_is_primary" \
  --value "true" \
  --sensitive false

# 4. Notify teams
echo "4️⃣ Notifying teams..."
curl -X POST "https://slack.com/api/chat.postMessage" \
  -H "Authorization: Bearer $SLACK_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"channel\": \"#incidents\",
    \"text\": \"🚨 GitHub Enterprise failover completed: $PRIMARY_REGION → $SECONDARY_REGION\"
  }"

echo "✅ Failover completed successfully!"
echo "📊 Monitor: https://status.acme.com/github"
```

## Monitoring & Observability

### Multi-Region Monitoring

```hcl
# monitoring/main.tf

module "github_monitoring" {
  source = "../../../"

  mode       = "organization"
  name       = "acme-monitoring"
  github_org = "acme-monitoring"

  # Monitoring repository
  repositories = {
    "github-metrics" = {
      description = "GitHub Enterprise metrics and monitoring"
      visibility  = "private"

      # Automated metrics collection
      webhooks = [
        {
          url          = "https://prometheus.acme.com/github/us-east"
          content_type = "json"
          events       = ["push", "pull_request", "issues", "repository"]
        },
        {
          url          = "https://prometheus.acme.com/github/eu-west"
          content_type = "json"
          events       = ["push", "pull_request", "issues", "repository"]
        }
      ]

      # Metrics dashboards
      files = [
        {
          file    = "dashboards/grafana-github.json"
          content = file("${path.module}/dashboards/grafana-github.json")
        }
      ]
    }
  }
}

# Outputs for monitoring
output "github_regions_health" {
  value = {
    us_east = {
      endpoint = "https://github.acme-us.com"
      repos    = length(module.github_us.repositories)
      status   = "active"
    }
    eu_west = {
      endpoint = "https://github.acme-eu.com"
      repos    = length(module.github_eu.repositories)
      status   = "active"
    }
    apac = {
      endpoint = "https://github.acme-apac.com"
      repos    = length(module.github_apac.repositories)
      status   = "active"
    }
  }
}
```

## Best Practices

### ✅ Multi-Region Best Practices

1. **Use consistent naming conventions** across regions
   ```
   repo-name-us
   repo-name-eu
   repo-name-apac
   ```

2. **Centralize policies** in shared modules

3. **Automate DR testing** quarterly

4. **Monitor cross-region replication lag**

5. **Document regional failover procedures**

6. **Use region-specific secrets** (never share across regions)

7. **Implement region-aware CI/CD** (deploy to correct region)

8. **Regular compliance audits** for each region

---

## Summary

Multi-region GitHub Enterprise management requires:
- ✅ Centralized Terraform configuration
- ✅ Region-specific provider configurations
- ✅ Shared security policies
- ✅ Automated synchronization
- ✅ DR procedures
- ✅ Comprehensive monitoring

This architecture enables global enterprises to maintain consistent governance while respecting regional requirements.
