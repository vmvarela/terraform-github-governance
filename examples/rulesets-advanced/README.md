# Advanced GitHub Rulesets Example

This example demonstrates **ALL GitHub ruleset features and edge cases** supported by the terraform-github-governance module.

## Overview

This configuration showcases **20 edge case categories** covering every aspect of GitHub rulesets:

1. **All Enforcement Levels** (3 examples)
2. **Complex Ref Patterns** (3 examples)
3. **All Bypass Actor Types** (2 examples)
4. **Comprehensive Pull Request Rules** (2 examples)
5. **Multiple Required Status Checks** (2 examples)
6. **Commit/Author/Committer Email Patterns** (2 examples)
7. **Branch Name Patterns - All Operators** (4 examples)
8. **Tag Name Patterns - All Operators** (3 examples)
9. **All Boolean Rules** (2 examples)
10. **Required Deployments** (2 examples)
11. **Code Scanning Requirements** (3 examples)
12. **Repository-Specific Rulesets** (1 example)
13. **Maximum Complexity Ruleset** (1 example)
14. **Pattern Negation** (1 example)
15. **Special Regex Characters** (2 examples)
16. **Minimal Rulesets** (2 examples)
17. **Wildcard Exclusions** (1 example)
18. **Multiple Rulesets on Same Branch** (2 examples)
19. **Empty Conditions (Anti-pattern)** (documented)
20. **Conflicting Patterns (Anti-pattern)** (1 example)

## Features Demonstrated

### Enforcement Levels

```hcl
enforcement = "active"    # Blocks non-compliant actions
enforcement = "evaluate"  # Dry-run mode (logs only)
enforcement = "disabled"  # Disabled but kept for reference
```

### Special Ref Patterns

- `~DEFAULT_BRANCH` - Matches the default branch (main/master)
- `~ALL` - Matches all branches
- `refs/heads/feature/**` - Wildcard patterns
- `refs/heads/release/v*` - Glob patterns

### Bypass Actors

```hcl
bypass_actors = {
  organization_admins = [true]              # Org admins can bypass
  repository_roles    = ["admin", "maintain"]  # By role
  teams               = ["platform-team"]      # By team slug
  integrations        = [12345]                # GitHub App IDs
}
```

### Pull Request Requirements

All PR options demonstrated:
- `required_approving_review_count` (0-6)
- `dismiss_stale_reviews_on_push`
- `require_code_owner_review`
- `require_last_push_approval`
- `required_review_thread_resolution`

### Pattern Operators

All pattern matching operators:
- `starts_with` - Prefix matching
- `ends_with` - Suffix matching
- `contains` - Substring matching
- `regex` - Full regex support (PCRE)

### Pattern Types

All commit-related patterns:
- `commit_message_pattern` - Enforce commit message format
- `commit_author_email_pattern` - Author email constraints
- `committer_email_pattern` - Committer email constraints
- `branch_name_pattern` - Branch naming conventions
- `tag_name_pattern` - Tag naming conventions

### Boolean Rules

All protection flags:
- `creation` - Prevent branch/tag creation
- `deletion` - Prevent branch/tag deletion
- `update` - Prevent force push (non-fast-forward)
- `required_linear_history` - No merge commits
- `required_signatures` - GPG signatures required

### Advanced Features

- **Required Deployments**: Gate merges on successful deployments
- **Code Scanning**: CodeQL integration with severity thresholds
- **Status Checks**: Multiple required checks with strict enforcement
- **Pattern Negation**: `negate = true` for inverse matching

## Edge Case Examples

### 1. Enforcement Levels

```hcl
# Active: Blocks violations
"edge-case-active-enforcement" = {
  enforcement = "active"
  # ...
}

# Evaluate: Logs violations but doesn't block
"edge-case-evaluate-mode" = {
  enforcement = "evaluate"
  # ...
}

# Disabled: Kept for documentation/future use
"edge-case-disabled-ruleset" = {
  enforcement = "disabled"
  # ...
}
```

### 2. Special Ref Patterns

```hcl
# Protect default branch (main or master)
conditions = {
  ref_name = {
    include = ["~DEFAULT_BRANCH"]
  }
}

# Apply to all branches except WIP
conditions = {
  ref_name = {
    include = ["~ALL"]
    exclude = ["refs/heads/wip/**"]
  }
}

# Complex wildcards
conditions = {
  ref_name = {
    include = [
      "refs/heads/feature/**",
      "refs/heads/bugfix/**",
      "refs/heads/hotfix/**"
    ]
    exclude = [
      "refs/heads/feature/poc-**",
      "refs/heads/bugfix/temp-**"
    ]
  }
}
```

### 3. No Bypass Actors (Maximum Security)

```hcl
bypass_actors = {
  organization_admins = [false]  # Even org admins can't bypass!
}

rules = {
  deletion                = true
  update                  = true
  required_signatures     = true
  required_linear_history = true
}
```

### 4. Comprehensive PR Requirements

```hcl
pull_request = {
  required_approving_review_count   = 2
  dismiss_stale_reviews_on_push     = true
  require_code_owner_review         = true
  require_last_push_approval        = true
  required_review_thread_resolution = true
}
```

### 5. Multiple Status Checks

```hcl
required_status_checks = {
  strict_required_status_checks_policy = true
  required_checks = [
    { context = "ci/unit-tests" },
    { context = "ci/integration-tests" },
    { context = "ci/e2e-tests" },
    { context = "security/code-scanning" },
    { context = "quality/sonarqube" }
  ]
}
```

### 6. Commit Patterns with Email Validation

```hcl
commit_message_pattern = {
  name     = "Jira Ticket Reference"
  pattern  = "\\[JIRA-[0-9]+\\]"
  operator = "regex"
  negate   = false
}

commit_author_email_pattern = {
  name     = "Corporate Email Only"
  pattern  = "@company\\.com$"
  operator = "regex"
  negate   = false
}

committer_email_pattern = {
  name     = "Verified Committers"
  pattern  = "@(company\\.com|trusted-partner\\.com)$"
  operator = "regex"
  negate   = false
}
```

### 7. Branch Name Patterns (All Operators)

```hcl
# Starts with
branch_name_pattern = {
  name     = "Team Prefix Required"
  pattern  = "team-[a-z]+-"
  operator = "starts_with"
}

# Ends with
branch_name_pattern = {
  name     = "Stable Suffix Required"
  pattern  = "-stable$"
  operator = "ends_with"
}

# Contains (with negation)
branch_name_pattern = {
  name     = "No Spaces in Branch Names"
  pattern  = " "
  operator = "contains"
  negate   = true  # Must NOT contain spaces
}

# Regex
branch_name_pattern = {
  name     = "Semantic Versioning"
  pattern  = "^release/v[0-9]+\\.[0-9]+\\.[0-9]+$"
  operator = "regex"
}
```

### 8. Tag Protection

```hcl
# Semantic versioning
tag_name_pattern = {
  name     = "Semantic Versioning Tags"
  pattern  = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
  operator = "regex"
}

# Calendar versioning
tag_name_pattern = {
  name     = "Calendar Versioning"
  pattern  = "^20[0-9]{2}\\.(0[1-9]|1[0-2])\\.(0[1-9]|[12][0-9]|3[01])\\.[0-9]+$"
  operator = "regex"
}

rules = {
  deletion = true  # Prevent tag deletion
  update   = true  # Prevent tag force-push
}
```

### 9. Required Deployments

```hcl
required_deployments = {
  required_deployment_environments = [
    "staging",
    "qa",
    "security-scan"
  ]
}
```

Merges to this branch are blocked until successful deployments to all listed environments.

### 10. Code Scanning Requirements

```hcl
# Block high/critical severity alerts
code_scanning = {
  required_analysis_tool = "CodeQL"
  security_alerts_threshold = "high_or_higher"
  alerts_types = ["security", "quality"]
}

# Block medium and above
code_scanning = {
  required_analysis_tool = "CodeQL"
  security_alerts_threshold = "medium_or_higher"
  alerts_types = ["security"]
}

# Block all severities (strictest)
code_scanning = {
  required_analysis_tool = "CodeQL"
  security_alerts_threshold = "all"
  alerts_types = ["security", "quality", "documentation"]
}
```

### 11. Pattern Negation

```hcl
# Block disposable email providers
commit_author_email_pattern = {
  name     = "Block Disposable Emails"
  pattern  = "@(tempmail\\.com|throwaway\\.email)$"
  operator = "regex"
  negate   = true  # Pattern must NOT match
}

# Commit messages must NOT be too short
commit_message_pattern = {
  name     = "Minimum Length"
  pattern  = "^.{0,9}$"  # 0-9 characters
  operator = "regex"
  negate   = true  # Must be 10+ chars
}
```

### 12. Maximum Complexity Example

The `edge-case-maximum-complexity` ruleset combines ALL features:
- All boolean protections
- Strict PR requirements (3 approvals)
- Multiple status checks
- Commit message + email patterns
- Deployment gates
- Code scanning
- No bypass actors

```hcl
"edge-case-maximum-complexity" = {
  enforcement = "active"
  target      = "branch"

  bypass_actors = {
    organization_admins = [false]
  }

  rules = {
    deletion                = true
    update                  = true
    required_linear_history = true
    required_signatures     = true

    pull_request = {
      required_approving_review_count   = 3
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = true
      require_last_push_approval        = true
      required_review_thread_resolution = true
    }

    required_status_checks = { /* ... */ }
    commit_message_pattern = { /* ... */ }
    commit_author_email_pattern = { /* ... */ }
    required_deployments = { /* ... */ }
    code_scanning = { /* ... */ }
  }
}
```

### 13. Multiple Rulesets on Same Branch

GitHub evaluates ALL matching rulesets and combines them:

```hcl
"ruleset-1" = {
  conditions = { ref_name = { include = ["refs/heads/main"] } }
  rules = { deletion = true }
}

"ruleset-2" = {
  conditions = { ref_name = { include = ["refs/heads/main"] } }
  rules = { required_linear_history = true }
}
```

Result: `main` branch has **both** deletion protection and linear history requirement.

## Usage

### Prerequisites

- Terraform >= 1.6
- GitHub Provider ~> 6.0
- GitHub organization with admin access
- GitHub Enterprise Cloud (for some advanced features like code scanning thresholds)

### Deployment

```bash
# 1. Copy configuration
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Set your organization

# 2. Initialize
terraform init

# 3. Plan
terraform plan

# 4. Apply
terraform apply

# 5. View outputs
terraform output edge_cases_by_category
terraform output features_demonstrated
```

### Testing Individual Rulesets

After deployment, test rulesets by:

1. **Clone a test repository**:
   ```bash
   gh repo clone your-org/demo-main-protected
   ```

2. **Try operations that should be blocked**:
   ```bash
   # Try to delete main branch (should fail)
   git push origin :main

   # Try to force push (should fail)
   git push --force origin main

   # Try to create PR without approvals (should fail)
   gh pr create --fill
   ```

3. **Verify status checks**:
   ```bash
   # Create PR and verify status checks are required
   gh pr create --base main --head feature/test
   gh pr checks
   ```

4. **Check commit message patterns**:
   ```bash
   # Commit without Jira reference (should fail if pattern required)
   git commit -m "fix bug"
   git push
   ```

## Outputs

Comprehensive outputs for understanding the configuration:

```bash
terraform output total_rulesets          # Total count
terraform output rulesets_by_enforcement # Active/evaluate/disabled
terraform output rulesets_by_target      # Branch vs tag
terraform output edge_cases_by_category  # Breakdown by category
terraform output features_demonstrated   # Complete feature list
```

Example output:

```hcl
edge_cases_by_category = {
  enforcement_levels    = 3
  ref_patterns          = 3
  bypass_actors         = 2
  pull_request_rules    = 2
  status_checks         = 2
  commit_patterns       = 2
  branch_patterns       = 4
  tag_patterns          = 3
  boolean_rules         = 2
  deployments           = 2
  code_scanning         = 3
  # ... more categories
}

features_demonstrated = {
  enforcement_levels = ["active", "evaluate", "disabled"]
  ref_patterns = ["~DEFAULT_BRANCH", "~ALL", "wildcards", "specific refs"]
  pattern_operators = ["starts_with", "ends_with", "contains", "regex"]
  # ... all features
}
```

## Real-World Patterns

### Production Branch Protection

```hcl
"production-protection" = {
  enforcement = "active"
  target      = "branch"

  conditions = {
    ref_name = { include = ["refs/heads/main", "refs/heads/production"] }
  }

  bypass_actors = {
    organization_admins = [false]
  }

  rules = {
    deletion                = true
    update                  = true
    required_linear_history = true

    pull_request = {
      required_approving_review_count = 2
      require_code_owner_review       = true
    }

    required_status_checks = {
      strict_required_status_checks_policy = true
      required_checks = [
        { context = "ci/tests" },
        { context = "security/scan" }
      ]
    }
  }
}
```

### Open Source Contribution Rules

```hcl
"opensource-contributions" = {
  enforcement = "active"
  target      = "branch"

  conditions = {
    ref_name = { include = ["refs/heads/main"] }
  }

  bypass_actors = {
    teams = ["maintainers"]
  }

  rules = {
    pull_request = {
      required_approving_review_count = 1
      require_code_owner_review       = true
    }

    commit_author_email_pattern = {
      name     = "Block Disposable Emails"
      pattern  = "@(tempmail\\.|throwaway\\.)"
      operator = "regex"
      negate   = true
    }
  }
}
```

### Release Branch Workflow

```hcl
"release-workflow" = {
  enforcement = "active"
  target      = "branch"

  conditions = {
    ref_name = { include = ["refs/heads/release/**"] }
  }

  rules = {
    deletion = true
    update   = true

    branch_name_pattern = {
      name     = "Semantic Version"
      pattern  = "^release/v[0-9]+\\.[0-9]+\\.[0-9]+$"
      operator = "regex"
    }

    pull_request = {
      required_approving_review_count = 2
    }

    required_deployments = {
      required_deployment_environments = ["staging"]
    }
  }
}
```

## Troubleshooting

### Ruleset Not Matching

If a ruleset doesn't seem to apply:

1. **Check ref pattern**: `refs/heads/main` vs `main`
2. **Check exclusions**: Branch may be excluded
3. **Check enforcement**: May be `evaluate` or `disabled`
4. **Check multiple rulesets**: Another ruleset may be more restrictive

### Pattern Not Matching

For regex patterns:

```bash
# Test regex locally
echo "feature/JIRA-123-add-feature" | grep -P "^feature/[A-Z]+-[0-9]+"

# Check escaping
# In HCL: "\\[JIRA-[0-9]+\\]"
# Becomes regex: \[JIRA-[0-9]+\]
```

### Bypass Not Working

If bypass actors aren't working:

1. **Verify team slugs**: Use `gh api orgs/YOUR_ORG/teams`
2. **Check organization_admins**: May be set to `false`
3. **Verify roles**: User must have specified role on repository

## Related Examples

- **[simple](../simple/)**: Basic module usage
- **[complete](../complete/)**: Comprehensive features
- **[large-scale](../large-scale/)**: 100+ repositories with org-wide rulesets

## Contributing

When adding new edge cases:

1. Add to appropriate category or create new category
2. Document in both `main.tf` and `README.md`
3. Update `edge_cases_by_category` output
4. Test with real GitHub API (not just `terraform plan`)

## References

- [GitHub Rulesets Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets)
- [GitHub Rulesets API](https://docs.github.com/en/rest/repos/rules)
- [Terraform GitHub Provider - Rulesets](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset)

## License

Apache 2.0 - See [LICENSE](../../LICENSE) for details.
