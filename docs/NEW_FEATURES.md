# New Features - Advanced Security & Governance

This document describes the newly implemented features for enhanced security and governance capabilities.

## 🔒 Security Managers

### Overview
Designate teams as security managers for your organization. Security managers can manage security alerts and settings for all repositories without requiring full admin access.

### Requirements
- **GitHub Plan**: Team or higher
- **Permissions**: Organization owner access

### Configuration

```hcl
module "github_governance" {
  source = "..."

  security_managers = ["security-team", "appsec-team"]
}
```

### Capabilities
Security managers can:
- ✅ Manage security and analysis settings for all repositories
- ✅ View security alerts across the organization
- ✅ Manage Dependabot and code scanning alerts
- ✅ Configure secret scanning settings
- ❌ Access admin features (destructive operations require admin)

### Use Cases
1. **Security Delegation**: Give security team members appropriate access without full admin rights
2. **Compliance**: Ensure security professionals can audit and configure security settings
3. **Least Privilege**: Follow security best practices by limiting administrative access

---

## 🏷️ Custom Properties Schema

### Overview
Define organization-wide custom properties that can be applied to repositories. These properties enable metadata-driven governance, categorization, and reporting.

### Requirements
- **GitHub Plan**: Enterprise Cloud
- **Permissions**: Organization owner access

### Configuration

```hcl
module "github_governance" {
  source = "..."

  custom_properties_schema = {
    "cost_center" = {
      description    = "Cost center for billing allocation"
      value_type     = "single_select"
      required       = true
      allowed_values = ["engineering", "sales", "marketing"]
      default_value  = "engineering"
    }
    "team_owner" = {
      description = "Team responsible for this repository"
      value_type  = "string"
      required    = true
    }
    "compliance_level" = {
      description    = "Required compliance level"
      value_type     = "single_select"
      required       = false
      allowed_values = ["sox", "pci", "hipaa", "none"]
    }
  }
}
```

### Property Types

| Type | Description | Example |
|------|-------------|---------|
| `string` | Free-form text | "backend-team" |
| `single_select` | One value from predefined list | "engineering" |

### Repository Usage

```hcl
repositories = {
  "my-api" = {
    description = "API service"

    custom_properties = {
      cost_center         = "engineering"
      team_owner          = "backend-team"
      compliance_level    = "sox"
    }
  }
}
```

### Use Cases
1. **Cost Allocation**: Track which cost center owns each repository
2. **Team Ownership**: Identify responsible teams for automated notifications
3. **Compliance Tracking**: Tag repositories by compliance requirements
4. **Data Classification**: Mark repositories by data sensitivity level

### Best Practices
- ✅ Use `single_select` for standardized values (enables reporting/filtering)
- ✅ Use descriptive names (e.g., `cost_center`, not `cc`)
- ✅ Mark critical properties as `required`
- ✅ Provide sensible `default_value` for optional properties
- ❌ Avoid free-form `string` properties where `single_select` would work

---

## 🔐 Workflow Permissions

### Overview
Control the default GitHub Actions workflow permissions and whether workflows can approve pull requests. This provides granular security control over what the `GITHUB_TOKEN` can do in workflows.

### Requirements
- **GitHub Plan**: Free or higher (all plans)
- **Permissions**: Repository admin access

### Configuration

#### Organization-Wide Default (Settings)

```hcl
settings = {
  # Apply to all new repositories
  workflow_permissions = {
    default_workflow_permissions = "read"   # Restrictive by default
    can_approve_pull_requests    = false    # Workflows cannot approve PRs
  }
}
```

#### Per-Repository Override

```hcl
repositories = {
  "ci-cd-intensive-app" = {
    description = "App with complex CI/CD needs"

    # Override organization default
    workflow_permissions = {
      default_workflow_permissions = "write"  # Workflows need write access
      can_approve_pull_requests    = false    # Still can't approve PRs
    }
  }
}
```

### Permission Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| `read` | Read-only access to repository contents | Security-first approach, workflows only read |
| `write` | Read + write access (create issues, PRs, etc.) | CI/CD workflows that need to publish artifacts, update docs |

### Security Considerations

#### ⚠️ **SECURITY WARNING: `can_approve_pull_requests`**
Enabling this setting allows workflows to approve pull requests, which can be a **significant security risk**:

- ❌ **DON'T**: Enable unless you have strong justification
- ❌ **DON'T**: Use with `write` permissions on public repositories
- ✅ **DO**: Keep disabled (default: `false`)
- ✅ **DO**: Use branch protection rules to require human approvals

#### 🔒 **Recommended Configuration**

```hcl
# ✅ Secure Default
workflow_permissions = {
  default_workflow_permissions = "read"
  can_approve_pull_requests    = false
}
```

### Use Cases

#### 1. **Security-First Repositories** (Default)
```hcl
workflow_permissions = {
  default_workflow_permissions = "read"
  can_approve_pull_requests    = false
}
```
- Workflows can only read code, cannot modify repository
- Ideal for: Security-sensitive applications, open-source projects

#### 2. **CI/CD Repositories**
```hcl
workflow_permissions = {
  default_workflow_permissions = "write"
  can_approve_pull_requests    = false
}
```
- Workflows can publish releases, update documentation, create issues
- Ideal for: Internal tools, automated publishing workflows

### Migration Strategy

If you have existing workflows that break with `read` permissions:

1. **Audit workflows**: Check which workflows need write access
2. **Use explicit tokens**: Update workflows to use PATs or GitHub Apps where appropriate
3. **Gradual rollout**: Start with `read` on new repos, migrate existing repos over time

```yaml
# Before: Implicit write via GITHUB_TOKEN
- uses: actions/checkout@v4

# After: Explicit write permission in workflow
permissions:
  contents: write
```

### Terraform Example

```hcl
module "github_governance" {
  source = "..."

  # Organization-wide secure default
  settings = {
    workflow_permissions = {
      default_workflow_permissions = "read"
      can_approve_pull_requests    = false
    }
  }

  repositories = {
    # Most repos inherit secure default (read-only)
    "secure-app" = {
      description = "Security-sensitive application"
      # Inherits: read permissions, cannot approve PRs
    }

    # CI/CD-heavy repos get write access
    "ci-cd-app" = {
      description = "App with automated releases"
      workflow_permissions = {
        default_workflow_permissions = "write"  # Override for CI/CD
        can_approve_pull_requests    = false    # Still cannot approve
      }
    }
  }
}
```

---

## 📊 Combined Example

```hcl
module "github_governance" {
  source = "..."
  mode   = "organization"
  name   = "my-org"

  # Security Managers
  security_managers = ["security-team", "appsec-team"]

  # Custom Properties Schema
  custom_properties_schema = {
    "cost_center" = {
      value_type     = "single_select"
      required       = true
      allowed_values = ["engineering", "sales", "marketing"]
    }
    "compliance_level" = {
      value_type     = "single_select"
      required       = false
      allowed_values = ["sox", "pci", "hipaa", "none"]
    }
  }

  # Organization Settings
  settings = {
    billing_email = "admin@example.com"

    # Secure workflow defaults
    workflow_permissions = {
      default_workflow_permissions = "read"
      can_approve_pull_requests    = false
    }
  }

  repositories = {
    "production-api" = {
      description = "Production API service"
      visibility  = "private"

      # Custom properties for governance
      custom_properties = {
        cost_center       = "engineering"
        compliance_level  = "sox"
      }

      # Override workflow permissions for CI/CD
      workflow_permissions = {
        default_workflow_permissions = "write"
        can_approve_pull_requests    = false
      }
    }
  }
}
```

---

## 🚀 Migration Guide

### From Previous Version

1. **No Breaking Changes**: All new features are opt-in
2. **Gradual Adoption**: Add features incrementally

### Step 1: Add Security Managers (if GitHub Team+)
```hcl
security_managers = ["security-team"]
```

### Step 2: Define Custom Properties (if GitHub Enterprise Cloud)
```hcl
custom_properties_schema = {
  "team_owner" = {
    value_type = "string"
    required   = true
  }
}
```

### Step 3: Set Workflow Permissions
```hcl
settings = {
  workflow_permissions = {
    default_workflow_permissions = "read"
    can_approve_pull_requests    = false
  }
}
```

### Step 4: Apply Custom Properties to Repos
```hcl
repositories = {
  "my-repo" = {
    custom_properties = {
      team_owner = "platform-team"
    }
  }
}
```

---

## ❓ FAQ

### Q: Do I need GitHub Enterprise Cloud for all features?
**A**: No. Only Custom Properties require Enterprise Cloud. Security Managers need Team+, Workflow Permissions work on all plans.

### Q: What happens if I set custom properties but don't have Enterprise Cloud?
**A**: Terraform will fail during `apply`. Remove the `custom_properties_schema` block.

### Q: Can I use `can_approve_pull_requests = true`?
**A**: Technically yes, but **strongly discouraged**. This creates security risks. Keep it `false`.

### Q: How do security managers differ from admins?
**A**: Security managers can only manage security settings. They cannot delete repos, manage billing, or perform destructive operations.

### Q: What if my workflows break with `read` permissions?
**A**: Either update workflows to request explicit permissions via `permissions:` block, or override with `write` for specific repos.

---

## 📚 Related Documentation

- [GitHub Security Managers](https://docs.github.com/en/organizations/managing-peoples-access-to-your-organization-with-roles/managing-security-managers-in-your-organization)
- [GitHub Custom Properties](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-organization-settings/managing-custom-properties-for-repositories-in-your-organization)
- [GitHub Actions Permissions](https://docs.github.com/en/actions/security-guides/automatic-token-authentication#permissions-for-the-github_token)
