# Error Code Reference

This document provides a complete reference for all error codes used in the terraform-github-governance module.

## Error Code Format

Error codes follow the format: `[TF-GH-XXX]`

- **TF** - Terraform
- **GH** - GitHub
- **XXX** - Sequential number (001-999)

All error messages include:
- ✅ Error code for easy reference
- ✅ Clear description of the problem
- ✅ Current state/context
- ✅ Actionable solutions (multiple options when possible)
- ✅ Links to relevant documentation

---

## Complete Error Code List

### TF-GH-001: Organization Webhooks Not Available

**Category:** Plan Limitation  
**Severity:** Error  
**Introduced:** v1.0.0

**Description:**  
Organization-level webhooks require a paid GitHub plan (Team, Business, or Enterprise). The Free plan only supports repository-level webhooks.

**When It Occurs:**
- You configure `webhooks = { ... }` in organization mode
- Your organization is on the Free plan

**Solutions:**
1. Use repository-level webhooks instead
2. Remove webhooks configuration
3. Upgrade to Team or higher plan

**Documentation:**
- [GitHub Webhooks Documentation](https://docs.github.com/en/organizations/managing-organization-settings/about-webhooks)

---

### TF-GH-002: Organization Rulesets Not Available

**Category:** Plan Limitation  
**Severity:** Error  
**Introduced:** v1.0.0

**Description:**  
Organization rulesets are a feature that requires GitHub Team, Business, or Enterprise plan.

**When It Occurs:**
- You configure `rulesets = { ... }` in organization mode
- Your organization is on the Free plan

**Solutions:**
1. Use repository-level branch protection rules
2. Remove rulesets configuration
3. Upgrade to Team or higher plan

**Documentation:**
- [Managing Rulesets for Repositories](https://docs.github.com/en/organizations/managing-organization-settings/managing-rulesets-for-repositories-in-your-organization)

---

### TF-GH-003: Custom Repository Roles Not Available

**Category:** Plan Limitation  
**Severity:** Error  
**Introduced:** v1.0.0

**Description:**  
Custom repository roles are an Enterprise-only feature that allows creating roles with specific permission sets beyond the standard roles.

**When It Occurs:**
- You configure `repository_roles = { ... }`
- Your organization is not on an Enterprise plan

**Solutions:**
1. Use standard GitHub roles (read, triage, write, maintain, admin)
2. Remove repository_roles configuration
3. Upgrade to GitHub Enterprise

**Standard Roles Available:**
- `read` - Can read and clone repositories
- `triage` - Can read and manage issues/PRs
- `write` - Can push to repositories
- `maintain` - Can manage repositories without sensitive actions
- `admin` - Full administrative access

**Documentation:**
- [Managing Custom Repository Roles](https://docs.github.com/en/enterprise-cloud@latest/organizations/managing-peoples-access-to-your-organization-with-roles/managing-custom-repository-roles-for-an-organization)

---

### TF-GH-004: Internal Repositories Not Available

**Category:** Plan Limitation  
**Severity:** Error  
**Introduced:** v1.0.0

**Description:**  
Internal repository visibility is only available on GitHub Business and Enterprise plans. Internal repos are visible to all organization members but not external users.

**When It Occurs:**
- You set `visibility = "internal"` for any repository
- Your organization is not on Business or Enterprise plan

**Solutions:**
1. Change repository visibility to `"private"` or `"public"`
2. Upgrade to Business or Enterprise plan

**Visibility Options by Plan:**
- **Free/Team:** `public`, `private`
- **Business/Enterprise:** `public`, `private`, `internal`

**Documentation:**
- [About Internal Repositories](https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories#about-internal-repositories)

---

### TF-GH-005: Runner Group Configuration Error

**Category:** Configuration Error  
**Severity:** Error  
**Introduced:** v1.0.0

**Description:**  
Runner groups with `visibility = "selected"` must specify at least one repository. Empty repository lists are not allowed.

**When It Occurs:**
- You configure a runner group with `visibility = "selected"`
- The `repositories` field is empty or omitted

**Solutions:**
1. Add repositories to the `repositories` list
2. Change `visibility` to `"all"` or `"private"`
3. In project mode, runner groups automatically include all project repositories

**Example Fix:**
```hcl
# ❌ Error
runner_groups = {
  "production" = {
    visibility = "selected"
    # Missing repositories!
  }
}

# ✅ Fixed
runner_groups = {
  "production" = {
    visibility   = "selected"
    repositories = ["api", "frontend"]
  }
}
```

**Documentation:**
- [Managing Self-Hosted Runners Using Groups](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/managing-access-to-self-hosted-runners-using-groups)

---

### TF-GH-006: Plaintext Secrets Deprecated

**Category:** Security / Deprecation  
**Severity:** Error  
**Introduced:** v1.0.0

**Description:**  
Storing plaintext secrets in the `secrets` variable is deprecated for security reasons. Terraform state files are not encrypted by default, exposing secrets to anyone with state access.

**When It Occurs:**
- You use the `secrets` variable with plaintext values
- Legacy configurations using deprecated `secrets` parameter

**Solutions:**
1. **Use `secrets_encrypted` variable** with GitHub CLI encryption:
   ```bash
   gh secret set SECRET_NAME --body "secret-value"
   ```

2. **Use external secret management:**
   - HashiCorp Vault
   - AWS Secrets Manager
   - Azure Key Vault
   - Google Secret Manager

3. **Retrieve encrypted value and use in Terraform:**
   ```hcl
   secrets_encrypted = {
     "DEPLOY_TOKEN" = "encrypted_base64_value"
   }
   ```

**Migration Steps:**
1. Encrypt your secrets using GitHub CLI
2. Update your Terraform configuration to use `secrets_encrypted`
3. Remove the `secrets` variable
4. Apply changes to update state

**Documentation:**
- [Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

---

### TF-GH-007: Plaintext Dependabot Secrets Deprecated

**Category:** Security / Deprecation  
**Severity:** Error  
**Introduced:** v1.0.0

**Description:**  
Similar to TF-GH-006, but specifically for Dependabot secrets. Plaintext storage in state files is a security risk.

**When It Occurs:**
- You use the `dependabot_secrets` variable with plaintext values

**Solutions:**
1. **Use `dependabot_secrets_encrypted` variable:**
   ```bash
   gh secret set NPM_TOKEN --app dependabot --body "npm-token-value"
   ```

2. **Update configuration:**
   ```hcl
   # ❌ Don't use
   dependabot_secrets = {
     "NPM_TOKEN" = "plaintext-value"
   }
   
   # ✅ Use this
   dependabot_secrets_encrypted = {
     "NPM_TOKEN" = "encrypted_base64_value"
   }
   ```

**Documentation:**
- [Configuring Access to Private Registries](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/configuring-access-to-private-registries-for-dependabot)

---

## Error Code Ranges

### 001-099: Plan Limitations
Errors related to GitHub plan requirements and feature availability.

- **001-010:** Organization-level features
- **011-020:** Repository-level features
- **021-030:** Actions and CI/CD features
- **031-040:** Security features

### 100-199: Configuration Errors
Errors related to invalid or incomplete configuration.

- **100-110:** Variable validation
- **111-120:** Resource configuration
- **121-130:** Mode-specific errors

### 200-299: Security Warnings
Security-related warnings and deprecations.

- **200-210:** Secrets management
- **211-220:** Access control
- **221-230:** Deprecated features

### 300-399: API Errors
Errors related to GitHub API interactions.

- **300-310:** Rate limiting
- **311-320:** Authentication
- **321-330:** Permissions

### 400-499: State Management
Errors related to Terraform state operations.

- **400-410:** Import errors
- **411-420:** Resource conflicts
- **421-430:** State drift

### 500-599: Runtime Errors
Errors that occur during resource creation/update.

- **500-510:** Network errors
- **511-520:** Validation failures
- **521-530:** Dependency errors

---

## Using Error Codes for Troubleshooting

### Quick Search
Use the error code to quickly find the solution:

1. **In README.md:** Search for the error code in the Troubleshooting section
2. **In this document:** Full reference with detailed solutions
3. **In GitHub Issues:** Search issues by error code
4. **In Documentation:** Error codes link to relevant docs

### Example Search Patterns

```bash
# Search in repository
grep -r "TF-GH-001" .

# Search in git history
git log --all --grep="TF-GH-001"

# Search GitHub issues
# Use GitHub search: is:issue "TF-GH-001"
```

---

## Contributing New Error Codes

When adding new error codes:

1. **Reserve the next sequential number** in the appropriate range
2. **Follow the format:**
   ```terraform
   error_message = <<-EOT
     [TF-GH-XXX] ❌ Clear error description
     
     Context: ${relevant_variable}
     
     Solutions:
       1. Solution with example
       2. Alternative solution
       3. Upgrade path (if applicable)
     
     Documentation: https://docs.github.com/...
   EOT
   ```

3. **Document in this file** with:
   - Category
   - Severity
   - Version introduced
   - When it occurs
   - Solutions with examples
   - Links to documentation

4. **Add to troubleshooting guide** in README.md if it's a common error

5. **Update test coverage** to validate the error condition

---

## Reserved Error Codes

The following error code ranges are reserved for future use:

- **600-699:** Third-party integrations
- **700-799:** Performance warnings
- **800-899:** Deprecated features
- **900-999:** Future expansion

---

**Last Updated:** 2025-11-10  
**Module Version:** 1.0.0
