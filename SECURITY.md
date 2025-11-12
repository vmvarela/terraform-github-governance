# Security Policy

## Overview

This document outlines the security considerations, best practices, and authentication methods for the Terraform GitHub Governance module.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Authentication Methods

### 🔐 Recommended: GitHub App (Production)

**Why?**
- ✅ Fine-grained permissions (principle of least privilege)
- ✅ Organization-level authentication
- ✅ Automatic token rotation
- ✅ Audit logging
- ✅ Can be scoped to specific repositories
- ✅ Higher rate limits (5,000 requests/hour)

**Setup Guide:**

#### 1. Create GitHub App

1. Navigate to your organization settings:
   ```
   https://github.com/organizations/YOUR_ORG/settings/apps/new
   ```

2. Fill in basic information:
   - **App name**: `Terraform Governance Bot`
   - **Homepage URL**: Your repository URL
   - **Webhook**: Uncheck "Active" (not needed for Terraform)

3. Configure permissions (minimum required):

   **Repository permissions:**
   - Actions: Read & Write
   - Administration: Read & Write
   - Contents: Read & Write
   - Dependabot secrets: Read & Write
   - Environments: Read & Write
   - Issues: Read & Write
   - Metadata: Read (automatic)
   - Pull requests: Read & Write
   - Secrets: Read & Write
   - Webhooks: Read & Write

   **Organization permissions:**
   - Actions runner groups: Read & Write
   - Actions variables: Read & Write
   - Administration: Read & Write
   - Custom properties: Admin (Enterprise Cloud only)
   - Members: Read
   - Organization actions secrets: Read & Write
   - Organization dependabot secrets: Read & Write
   - Webhooks: Read & Write

4. Click **Create GitHub App**

#### 2. Generate Private Key

1. Scroll to "Private keys" section
2. Click **Generate a private key**
3. Save the downloaded `.pem` file securely
4. Store it as a secret in your CI/CD system or use a secrets manager

#### 3. Install the App

1. Go to "Install App" in the left sidebar
2. Install on your organization
3. Select "All repositories" or specific repositories
4. Note the **Installation ID** from the URL:
   ```
   https://github.com/organizations/YOUR_ORG/settings/installations/INSTALLATION_ID
   ```

#### 4. Configure Terraform

```hcl
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = "your-org"

  app_auth {
    id              = "123456"  # App ID from app settings
    installation_id = "12345678"  # Installation ID from step 3
    pem_file        = file("path/to/private-key.pem")
  }
}

module "github_governance" {
  source = "vmvarela/governance/github"

  mode = "organization"
  name = "your-org"

  # ... rest of configuration
}
```

**Security Best Practices:**
- ✅ Store private key in a secrets manager (AWS Secrets Manager, HashiCorp Vault, etc.)
- ✅ Rotate keys periodically (recommended: every 90 days)
- ✅ Use separate apps for different environments (dev, staging, prod)
- ✅ Enable "Restrict to specific repositories" for project mode
- ✅ Monitor app activity in audit logs

---

### 🔑 Alternative: Personal Access Token (PAT)

**Use Cases:**
- ⚠️ Development/testing only
- ⚠️ Personal projects
- ❌ NOT recommended for production

**Why Less Secure?**
- ❌ Tied to a user account (security risk if user leaves)
- ❌ No automatic rotation
- ❌ Broader permissions than necessary
- ❌ Lower rate limits (5,000 requests/hour for authenticated users)
- ❌ Less granular audit logging

**Setup Guide:**

#### 1. Create Fine-Grained PAT (Recommended over Classic)

1. Go to: https://github.com/settings/tokens?type=beta
2. Click **Generate new token (fine-grained)**
3. Configure:
   - **Token name**: `Terraform Governance`
   - **Expiration**: 90 days (maximum)
   - **Resource owner**: Select your organization
   - **Repository access**:
     - Organization mode: "All repositories"
     - Project mode: "Only select repositories"

4. Permissions (match GitHub App permissions above):
   - Repository permissions: Administration, Actions, Contents, Secrets, etc.
   - Organization permissions: Administration, Members, Webhooks, etc.

5. Click **Generate token** and save securely

#### 2. Configure Terraform

```hcl
provider "github" {
  owner = "your-org"
  token = var.github_token  # NEVER hardcode tokens
}
```

**In your terraform.tfvars or environment:**
```bash
# Option 1: Environment variable (recommended)
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# Option 2: tfvars file (add to .gitignore!)
github_token = "ghp_xxxxxxxxxxxx"
```

**Security Best Practices:**
- ✅ Use fine-grained tokens (not classic)
- ✅ Set shortest expiration possible
- ✅ Store in environment variables or secrets manager
- ✅ Never commit tokens to version control
- ✅ Use separate tokens per environment
- ✅ Revoke immediately if compromised

---

## Secret Management

### Terraform Variables with Secrets

This module uses `sensitive = true` for all secret-related variables:

```hcl
variable "secrets_plaintext" {
  description = "Organization secrets (plaintext - for testing only)"
  type        = map(string)
  default     = {}
  sensitive   = true  # 🔒 Hidden in logs/output
}
```

**Best Practices:**

1. **Use Encrypted Secrets** (Recommended):
   ```hcl
   module "github_governance" {
     source = "..."

     # ✅ GOOD: Pre-encrypted secrets
     secrets_encrypted = {
       "DATABASE_URL" = data.aws_secretsmanager_secret_version.db_url.secret_string
     }
   }
   ```

2. **Use External Data Sources**:
   ```hcl
   data "aws_secretsmanager_secret_version" "github_secrets" {
     secret_id = "github/actions/secrets"
   }

   locals {
     secrets = jsondecode(data.aws_secretsmanager_secret_version.github_secrets.secret_string)
   }

   module "github_governance" {
     source = "..."

     secrets_encrypted = local.secrets
   }
   ```

3. **Never Use Plaintext in Production**:
   ```hcl
   # ❌ BAD: Plaintext secrets in code
   secrets_plaintext = {
     "API_KEY" = "sk_live_xxxxxxxxxxxx"
   }

   # ✅ GOOD: Use encryption or external sources
   secrets_encrypted = {
     "API_KEY" = data.external.encrypted_secret.result.value
   }
   ```

---

## State File Security

### ⚠️ Critical: Terraform State Contains Secrets

Terraform state files contain ALL resource attributes, including secrets in plaintext.

**Required Protections:**

1. **Use Remote State with Encryption**:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "terraform-state"
       key            = "github-governance/terraform.tfstate"
       region         = "us-west-2"
       encrypt        = true  # 🔒 Encrypt at rest
       dynamodb_table = "terraform-locks"

       # Server-side encryption with KMS
       kms_key_id = "arn:aws:kms:us-west-2:123456789:key/xxxxx"
     }
   }
   ```

2. **Restrict State Access**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject"
         ],
         "Resource": "arn:aws:s3:::terraform-state/github-governance/*",
         "Condition": {
           "StringEquals": {
             "aws:PrincipalTag/Role": "TerraformRunner"
           }
         }
       }
     ]
   }
   ```

3. **Enable Versioning and Logging**:
   ```hcl
   resource "aws_s3_bucket_versioning" "terraform_state" {
     bucket = aws_s3_bucket.terraform_state.id

     versioning_configuration {
       status = "Enabled"
     }
   }

   resource "aws_s3_bucket_logging" "terraform_state" {
     bucket = aws_s3_bucket.terraform_state.id

     target_bucket = aws_s3_bucket.logs.id
     target_prefix = "terraform-state-access/"
   }
   ```

4. **Never Commit State Files**:
   ```gitignore
   # .gitignore
   *.tfstate
   *.tfstate.*
   .terraform/
   ```

---

## Network Security

### GitHub API Access

**Firewall Rules:**

If running Terraform in a restricted network, allow outbound HTTPS to:
```
- api.github.com (443/tcp)
- github.com (443/tcp)
```

**Proxy Configuration:**

```bash
export HTTPS_PROXY="https://proxy.company.com:8080"
export NO_PROXY="localhost,127.0.0.1"
```

Or in Terraform Cloud/Enterprise:
```hcl
# Organization settings > Variable sets
HTTPS_PROXY = "https://proxy.company.com:8080"
```

---

## Audit Logging

### GitHub Audit Log

Monitor module actions in GitHub's audit log:
```
https://github.com/organizations/YOUR_ORG/settings/audit-log
```

**Key Events to Monitor:**
- `org.add_member` / `org.remove_member`
- `repo.create` / `repo.destroy`
- `repo_secret.create` / `repo_secret.remove`
- `org_secret.create` / `org_secret.remove`
- `team.add_member` / `team.remove_member`

**Export Audit Logs** (Enterprise only):
```bash
# Via GitHub CLI
gh api \
  -H "Accept: application/vnd.github+json" \
  /orgs/YOUR_ORG/audit-log \
  > audit-log.json
```

### Terraform Cloud Audit Trails

Enable audit logging in Terraform Cloud:
1. Organization Settings > Security
2. Enable "Audit Trail Logging"
3. Configure destination (S3, CloudWatch, etc.)

---

## Incident Response

### If Credentials are Compromised

**Immediate Actions:**

1. **Revoke Credentials**:
   - GitHub App: Settings > Developer settings > GitHub Apps > Revoke all tokens
   - PAT: Settings > Developer settings > Personal access tokens > Delete

2. **Rotate Secrets**:
   ```bash
   # List all secrets to rotate
   terraform state list | grep secret

   # Update secrets in GitHub
   # (Use GitHub UI or API, not Terraform to avoid state conflicts)
   ```

3. **Audit Impact**:
   ```bash
   # Check GitHub audit log
   gh api /orgs/YOUR_ORG/audit-log \
     --jq '.[] | select(.created_at > "2024-01-01T00:00:00Z")'

   # Check Terraform state for unauthorized changes
   terraform state pull > state-backup.json
   diff state-backup.json previous-state.json
   ```

4. **Notify Team**:
   - Security team
   - Engineering management
   - Compliance officer (if applicable)

5. **Document Incident**:
   - Timeline of events
   - Credentials exposed
   - Actions taken
   - Preventive measures

### Recovery Procedures

1. **Generate New Credentials**:
   - Follow setup guides above
   - Use new key/token names

2. **Update CI/CD**:
   ```bash
   # Update secrets in GitHub Actions
   gh secret set GITHUB_TOKEN -b "new_token_here"

   # Update secrets in Terraform Cloud
   # Via UI or API
   ```

3. **Re-apply Terraform**:
   ```bash
   terraform init -reconfigure
   terraform plan
   terraform apply
   ```

4. **Verify Security**:
   - Check audit logs for suspicious activity
   - Run security scan on repositories
   - Verify all secrets were rotated

---

## Security Checklist

### Initial Setup

- [ ] Use GitHub App authentication (production)
- [ ] Store private keys in secrets manager
- [ ] Configure remote state with encryption
- [ ] Enable state file versioning
- [ ] Restrict state file access
- [ ] Add `.tfstate` to `.gitignore`
- [ ] Enable GitHub audit logging
- [ ] Set up monitoring/alerts

### Ongoing Operations

- [ ] Rotate credentials every 90 days
- [ ] Review audit logs monthly
- [ ] Update provider versions regularly
- [ ] Review and minimize permissions
- [ ] Scan for exposed secrets (git-secrets, truffleHog)
- [ ] Document security procedures
- [ ] Train team on security practices

### Before Production

- [ ] Security review completed
- [ ] Secrets encrypted in state
- [ ] Backup/disaster recovery tested
- [ ] Incident response plan documented
- [ ] Team trained on procedures
- [ ] Monitoring/alerting configured

---

## Reporting Security Issues

**Please DO NOT open public issues for security vulnerabilities.**

Instead:

1. **Email**: [Your security email]
2. **Subject**: `[SECURITY] Terraform GitHub Governance Module`
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

**Response Time:**
- Acknowledge: Within 24 hours
- Initial assessment: Within 3 days
- Fix timeline: Depends on severity (critical: 7 days, high: 14 days)

---

## Additional Resources

- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [Terraform Security](https://developer.hashicorp.com/terraform/tutorials/configuration-language/sensitive-variables)
- [GitHub App Permissions](https://docs.github.com/en/rest/overview/permissions-required-for-github-apps)
- [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

---

**Last Updated**: November 12, 2025
**Version**: 1.0.0
