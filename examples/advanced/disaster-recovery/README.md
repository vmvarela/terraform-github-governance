# Disaster Recovery Playbook for GitHub Governance

This playbook provides step-by-step procedures for recovering from various disaster scenarios affecting your GitHub infrastructure managed by this Terraform module.

## 📋 Table of Contents

- [Overview](#overview)
- [Preparation](#preparation)
- [Disaster Scenarios](#disaster-scenarios)
  - [Scenario 1: Accidental Repository Deletion](#scenario-1-accidental-repository-deletion)
  - [Scenario 2: Terraform State Corruption](#scenario-2-terraform-state-corruption)
  - [Scenario 3: Mass Configuration Drift](#scenario-3-mass-configuration-drift)
  - [Scenario 4: GitHub Organization Compromise](#scenario-4-github-organization-compromise)
  - [Scenario 5: Complete GitHub Outage](#scenario-5-complete-github-outage)
- [Recovery Time Objectives](#recovery-time-objectives)
- [Post-Incident Review](#post-incident-review)

## Overview

### RTO/RPO Targets

| Disaster Type | RTO (Recovery Time) | RPO (Data Loss) | Priority |
|---------------|---------------------|-----------------|----------|
| Single repo deletion | 15 minutes | 0 (restore from backup) | P1 |
| State corruption | 30 minutes | 0 (state backup) | P1 |
| Configuration drift | 1 hour | 0 (declarative IaC) | P2 |
| Org compromise | 2 hours | 0 (audit logs) | P0 |
| GitHub outage | 4 hours | N/A (vendor issue) | P0 |

### Disaster Response Team

```
┌─────────────────────────────────────────────────────────┐
│  INCIDENT COMMANDER                                     │
│  • Declares disaster                                    │
│  • Coordinates response                                 │
│  • Communicates with stakeholders                       │
└─────────────────────────────────────────────────────────┘
              ↓           ↓           ↓
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │ Tech Lead   │ │ SRE Team    │ │ Security    │
    │             │ │             │ │             │
    │ • Terraform │ │ • Infra     │ │ • Access    │
    │ • GitHub    │ │ • Backups   │ │ • Audit     │
    └─────────────┘ └─────────────┘ └─────────────┘
```

## Preparation

### Before Disaster Strikes

#### 1. Enable Automated Backups

```hcl
# backup-config.tf

# Automated state backups to S3
terraform {
  backend "s3" {
    bucket         = "acme-terraform-state"
    key            = "github/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"

    # Enable versioning for state history
    versioning = true
  }
}

# Daily state snapshots
resource "null_resource" "daily_state_backup" {
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      DATE=$(date +%Y%m%d-%H%M%S)
      terraform state pull > backups/state-backup-$DATE.json

      # Upload to S3 with retention
      aws s3 cp backups/state-backup-$DATE.json \
        s3://acme-terraform-backups/github/daily/$DATE.json \
        --storage-class STANDARD_IA

      # Delete local backups older than 7 days
      find backups/ -name "state-backup-*.json" -mtime +7 -delete
    EOT
  }
}
```

#### 2. Setup GitHub Organization Backup

```bash
#!/bin/bash
# scripts/backup-github-org.sh
# Runs daily via cron: 0 2 * * * /path/to/backup-github-org.sh

GITHUB_ORG="acme-corp"
BACKUP_DIR="/backups/github/$(date +%Y%m%d)"
GH_TOKEN="${GITHUB_BACKUP_TOKEN}"

mkdir -p "$BACKUP_DIR"

echo "🔄 Starting GitHub organization backup..."

# Backup repositories
gh repo list "$GITHUB_ORG" --limit 1000 --json name,description,visibility,isArchived,defaultBranch,createdAt > "$BACKUP_DIR/repositories.json"

# Backup teams
gh api "/orgs/$GITHUB_ORG/teams?per_page=100" > "$BACKUP_DIR/teams.json"

# Backup organization settings
gh api "/orgs/$GITHUB_ORG" > "$BACKUP_DIR/organization.json"

# Backup webhooks
gh api "/orgs/$GITHUB_ORG/hooks" > "$BACKUP_DIR/webhooks.json"

# Backup secrets (metadata only, not values)
gh api "/orgs/$GITHUB_ORG/actions/secrets" > "$BACKUP_DIR/secrets-metadata.json"

# Backup runner groups
gh api "/orgs/$GITHUB_ORG/actions/runner-groups" > "$BACKUP_DIR/runner-groups.json"

# Create tarball
tar -czf "/backups/github-org-backup-$(date +%Y%m%d).tar.gz" -C /backups/github "$(date +%Y%m%d)"

# Upload to S3 with 90-day retention
aws s3 cp "/backups/github-org-backup-$(date +%Y%m%d).tar.gz" \
  s3://acme-backups/github/ \
  --storage-class GLACIER

echo "✅ Backup completed: $BACKUP_DIR"
```

#### 3. Document Emergency Access

```yaml
# emergency-access.yml
# Store in secure vault (HashiCorp Vault, 1Password, etc.)

emergency_contacts:
  incident_commander:
    name: "Jane Doe"
    phone: "+1-555-0100"
    email: "jane.doe@acme.com"

  github_admin:
    name: "John Smith"
    phone: "+1-555-0101"
    email: "john.smith@acme.com"

  terraform_admin:
    name: "Alice Johnson"
    phone: "+1-555-0102"
    email: "alice.johnson@acme.com"

emergency_credentials:
  github_backup_token:
    location: "vault://secrets/github/backup-token"
    permissions: ["admin:org", "repo", "delete_repo"]

  terraform_backend:
    location: "vault://secrets/terraform/github-backend"
    credentials: "AWS IAM role arn:aws:iam::123456789012:role/TerraformAdmin"

  break_glass_account:
    description: "Emergency GitHub organization owner account"
    location: "vault://secrets/github/break-glass"
    mfa: "Hardware token in safe"
```

## Disaster Scenarios

### Scenario 1: Accidental Repository Deletion

**Symptoms:**
- Repository suddenly disappears from GitHub
- Terraform state still shows repository
- Developers report 404 errors

**Impact:** High (data loss, workflow disruption)

**Recovery Procedure:**

#### Step 1: Assess the Damage

```bash
# Check if repo exists in GitHub
gh repo view acme-corp/deleted-repo
# Error: Could not resolve to a Repository with the name 'acme-corp/deleted-repo'

# Check Terraform state
terraform state show 'module.github_governance.github_repository.repo["deleted-repo"]'
# Shows resource still in state

# Check GitHub audit log
gh api /orgs/acme-corp/audit-log?phrase=repo.destroy | jq '.[] | select(.repo == "acme-corp/deleted-repo")'
```

#### Step 2: Immediate Response (5 minutes)

```bash
# 1. Prevent further changes
echo "⚠️  INCIDENT: Repository deleted - pausing all Terraform operations"

# 2. Lock Terraform state
terraform state lock

# 3. Notify stakeholders
./scripts/notify-incident.sh "P1: Repository 'deleted-repo' accidentally deleted"
```

#### Step 3: Restore from Backup (10 minutes)

**Option A: Restore from GitHub (if deleted < 90 days)**

```bash
# GitHub keeps deleted repos for 90 days
# Contact GitHub Support to restore

# Or use API if you have the repo ID
REPO_ID=12345678
gh api -X POST "/repositories/$REPO_ID/restore"
```

**Option B: Restore from Git Backup**

```bash
# If you have a local clone or backup
cd /backups/repositories/deleted-repo

# Recreate repository via Terraform
terraform apply -target='module.github_governance.github_repository.repo["deleted-repo"]'

# Push backup content
git remote add origin https://github.com/acme-corp/deleted-repo.git
git push -u origin --all
git push origin --tags
```

**Option C: Restore from Terraform Drift Detection**

```bash
# Terraform will detect the repo is missing and recreate it
terraform plan
# Plan: 1 to add, 0 to change, 0 to destroy

# Apply to recreate
terraform apply -target='module.github_governance.github_repository.repo["deleted-repo"]'

# Restore content from backup
./scripts/restore-repo-content.sh deleted-repo /backups/repositories/deleted-repo
```

#### Step 4: Verify Recovery (5 minutes)

```bash
# Check repo exists
gh repo view acme-corp/deleted-repo

# Verify branches
gh api /repos/acme-corp/deleted-repo/branches

# Verify protection rules
gh api /repos/acme-corp/deleted-repo/branches/main/protection

# Run Terraform plan (should show no changes)
terraform plan -detailed-exitcode
# Exit code should be 0
```

#### Step 5: Post-Recovery Actions

```hcl
# Add prevent_destroy to prevent future accidents

resource "github_repository" "repo" {
  for_each = local.repositories
  name     = each.key
  # ... other config ...

  lifecycle {
    prevent_destroy = true  # 🛡️ ADD THIS
  }
}
```

**Total Recovery Time: ~20 minutes**

---

### Scenario 2: Terraform State Corruption

**Symptoms:**
- `terraform plan` fails with state errors
- Resources show unexpected drift
- State file is invalid JSON

**Impact:** Critical (can't manage infrastructure)

**Recovery Procedure:**

#### Step 1: Diagnose Corruption

```bash
# Download current state
terraform state pull > current-state.json

# Validate JSON
jq . current-state.json > /dev/null
# If error: state is corrupted

# Check state file integrity
terraform state list
# Error: state snapshot was created by Terraform vX.X.X, which is newer...
```

#### Step 2: Restore from Backup

```bash
# List available backups
aws s3 ls s3://acme-terraform-state/github/ --recursive | grep tfstate

# Download latest good backup
LATEST_BACKUP=$(aws s3 ls s3://acme-terraform-backups/github/daily/ | tail -1 | awk '{print $4}')
aws s3 cp "s3://acme-terraform-backups/github/daily/$LATEST_BACKUP" restored-state.json

# Validate backup
jq . restored-state.json > /dev/null && echo "✅ Backup is valid"

# Push restored state
terraform state push restored-state.json
```

#### Step 3: Verify State Integrity

```bash
# Run plan to check for drift
terraform plan -detailed-exitcode

# If drift detected, investigate
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan | jq '.resource_changes[] | select(.change.actions != ["no-op"])'
```

#### Step 4: Reconcile Drift (if any)

```bash
# Option 1: Accept current GitHub state as source of truth
terraform import module.github_governance.github_repository.repo["repo-name"] "repo-name"

# Option 2: Force Terraform config to match
terraform apply -auto-approve
```

**Total Recovery Time: ~30 minutes**

---

### Scenario 3: Mass Configuration Drift

**Symptoms:**
- Multiple repositories show configuration drift
- Manual changes detected in GitHub UI
- `terraform plan` shows many updates

**Impact:** Medium (configuration inconsistency)

**Recovery Procedure:**

#### Step 1: Identify Drift

```bash
# Run plan and export drift report
terraform plan -out=drift.tfplan
terraform show -json drift.tfplan > drift-report.json

# Analyze drift
jq -r '.resource_changes[] |
  select(.change.actions != ["no-op"]) |
  "\(.address): \(.change.actions | join(","))"' drift-report.json

# Example output:
# module.github_governance.github_repository.repo["backend-api"]: update
# module.github_governance.github_branch_protection.protected["backend-api/main"]: update
```

#### Step 2: Categorize Changes

```bash
# scripts/analyze-drift.sh

#!/bin/bash
# Categorizes drift by severity

terraform show -json drift.tfplan | jq -r '
  .resource_changes[] |
  select(.change.actions != ["no-op"]) |
  {
    resource: .address,
    action: .change.actions[0],
    changes: [.change.before, .change.after]
  }
' | while read -r change; do
  # Check if change affects security
  if echo "$change" | grep -qE "branch_protection|vulnerability|secret"; then
    echo "CRITICAL: $change"
  elif echo "$change" | grep -qE "description|topics"; then
    echo "INFO: $change"
  else
    echo "WARN: $change"
  fi
done
```

#### Step 3: Decision Matrix

```
┌──────────────────────────────────────────────────────┐
│  Drift Type          │ Action                        │
├──────────────────────┼───────────────────────────────┤
│  Security settings   │ ENFORCE Terraform (apply)     │
│  Branch protections  │ ENFORCE Terraform (apply)     │
│  Webhooks            │ ENFORCE Terraform (apply)     │
│  Topics/Description  │ ACCEPT GitHub (ignore_changes)│
│  Archived status     │ ACCEPT GitHub (import)        │
└──────────────────────────────────────────────────────┘
```

#### Step 4: Remediate Drift

**Option A: Enforce Terraform Configuration**

```bash
# For security-critical settings, enforce Terraform
terraform apply -target=module.github_governance.github_branch_protection.protected
```

**Option B: Accept GitHub State**

```hcl
# For acceptable drift, add to ignore_changes
resource "github_repository" "repo" {
  for_each = local.repositories
  # ... config ...

  lifecycle {
    ignore_changes = [
      topics,        # Teams can update via UI
      description,   # Allow manual updates
      homepage_url,  # Marketing team manages
    ]
  }
}
```

**Option C: Mass Import**

```bash
# For archived repos or other accepted changes
./scripts/mass-import.sh < drift-resources.txt
```

#### Step 5: Prevent Future Drift

```hcl
# Enable drift detection in CI/CD

# .github/workflows/drift-detection.yml
name: Drift Detection

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours

jobs:
  detect-drift:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Init
        run: terraform init

      - name: Detect Drift
        id: drift
        run: |
          terraform plan -detailed-exitcode
          echo "exit_code=$?" >> $GITHUB_OUTPUT
        continue-on-error: true

      - name: Alert on Drift
        if: steps.drift.outputs.exit_code == '2'
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "⚠️ Configuration drift detected in GitHub infrastructure",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "Configuration drift detected. Review: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

**Total Recovery Time: ~1 hour**

---

### Scenario 4: GitHub Organization Compromise

**Symptoms:**
- Unexpected changes to organization settings
- Unknown users added as owners
- Suspicious repository activity
- Audit log shows unauthorized access

**Impact:** Critical (security breach)

**Recovery Procedure:**

#### Step 1: Immediate Response (0-15 minutes)

```bash
# 1. LOCK DOWN IMMEDIATELY
echo "🚨 SECURITY INCIDENT: Organization compromise detected"

# 2. Revoke all personal access tokens
gh api -X DELETE /orgs/acme-corp/personal-access-tokens

# 3. Require 2FA for all members (if not already)
gh api -X PUT /orgs/acme-corp -f two_factor_requirement_enabled=true

# 4. Remove suspicious users
gh api /orgs/acme-corp/members?role=admin | jq -r '.[].login' | while read user; do
  echo "Reviewing admin: $user"
  # Review and remove if unauthorized
  # gh api -X DELETE "/orgs/acme-corp/members/$user"
done

# 5. Disable GitHub Actions (temporarily)
gh api -X PUT /orgs/acme-corp -f actions_allowed=none
```

#### Step 2: Audit and Investigate (15-60 minutes)

```bash
# Download complete audit log
START_DATE=$(date -d '7 days ago' +%s)
gh api "/orgs/acme-corp/audit-log?phrase=created:>$START_DATE&per_page=100" > audit-log-incident.json

# Analyze suspicious activity
jq -r '.[] | select(.action | startswith("org.")) |
  {timestamp: .created_at, action: .action, actor: .actor, ip: .actor_ip}' \
  audit-log-incident.json

# Check for:
# - org.add_member (unauthorized users)
# - org.update_member (permission changes)
# - repo.create (malicious repos)
# - repo_secret.create (exfiltrated secrets)
# - oauth_application.create (backdoor apps)
```

#### Step 3: Remediation (60-90 minutes)

```bash
# 1. Restore organization settings from Terraform
terraform apply -target=module.github_governance.github_organization_settings

# 2. Restore webhooks from known-good state
terraform apply -target=module.github_governance.github_organization_webhook

# 3. Rotate all secrets
./scripts/rotate-all-secrets.sh

# 4. Remove unauthorized repositories
gh repo list acme-corp --json name,createdAt | \
  jq -r '.[] | select(.createdAt > "2025-11-11T00:00:00Z") | .name' | \
  while read repo; do
    echo "Reviewing recent repo: $repo"
    # Manually review and delete if malicious
    # gh repo delete "acme-corp/$repo" --yes
  done

# 5. Restore branch protections
terraform apply -target=module.github_governance.github_branch_protection
```

#### Step 4: Secret Rotation

```bash
#!/bin/bash
# scripts/rotate-all-secrets.sh

SECRETS=$(gh api /orgs/acme-corp/actions/secrets | jq -r '.secrets[].name')

for secret in $SECRETS; do
  echo "🔄 Rotating secret: $secret"

  # Generate new value (example for AWS keys)
  case $secret in
    AWS_ACCESS_KEY_ID)
      NEW_VALUE=$(aws iam create-access-key --user-name github-actions --query 'AccessKey.AccessKeyId' --output text)
      ;;
    AWS_SECRET_ACCESS_KEY)
      NEW_VALUE=$(aws iam create-access-key --user-name github-actions --query 'AccessKey.SecretAccessKey' --output text)
      ;;
    *)
      echo "⚠️  Manual rotation required for: $secret"
      continue
      ;;
  esac

  # Encrypt with GitHub public key
  ENCRYPTED=$(./scripts/encrypt-github-secret.sh "$NEW_VALUE")

  # Update secret
  gh api -X PUT "/orgs/acme-corp/actions/secrets/$secret" \
    -f encrypted_value="$ENCRYPTED"

  echo "✅ Rotated: $secret"
done
```

#### Step 5: Post-Incident Hardening

```hcl
# Enhanced security configuration

module "github_governance" {
  source = "../../.."

  # Force SAML SSO
  saml_enabled = true

  # Require 2FA
  two_factor_requirement = true

  # Restrict token permissions
  members_can_create_repositories = false
  members_can_create_pages        = false

  # Enhanced audit logging
  webhooks = [{
    url          = "https://siem.acme.com/github-audit"
    content_type = "json"
    events       = ["*"]  # All events
  }]

  # IP allowlist
  ip_allow_list = [
    "203.0.113.0/24",  # Office network
    "198.51.100.0/24", # VPN
  ]
}
```

**Total Recovery Time: ~2 hours**

---

### Scenario 5: Complete GitHub Outage

**Symptoms:**
- GitHub.com or GitHub Enterprise Server is down
- API returns 503 errors
- No access to repositories

**Impact:** Critical (complete service disruption)

**Recovery Procedure:**

#### Step 1: Verify Outage (0-5 minutes)

```bash
# Check GitHub status
curl -s https://www.githubstatus.com/api/v2/status.json | jq '.status.indicator'
# Output: "major" (outage confirmed)

# Check GitHub Enterprise Server (if self-hosted)
curl -f https://github.acme.com/api/v3/meta
# Connection refused or timeout

# Verify it's not a local issue
curl -I https://github.com
# 503 Service Unavailable
```

#### Step 2: Activate Disaster Recovery Mode (5-15 minutes)

```bash
# 1. Switch to read-only local mirrors
echo "📡 Activating local Git mirrors..."

# Update developer machines to use local mirrors
for repo in $(cat critical-repos.txt); do
  echo "Updating remote for: $repo"
  git -C "/mirrors/$repo" remote set-url origin "file:///mirrors/$repo"
done

# 2. Enable local CI/CD (GitLab Runner, Jenkins, etc.)
./scripts/enable-local-ci.sh

# 3. Notify all teams
./scripts/notify-outage.sh "GitHub outage detected - using local mirrors"
```

#### Step 3: Continue Operations with Mirrors (During Outage)

```bash
# Developers can continue working with local mirrors
cd /work/my-repo
git fetch origin  # Uses local mirror
git push origin feature-branch  # Pushes to local mirror

# Local CI/CD processes changes
# Changes will sync back to GitHub when service resumes
```

#### Step 4: Monitor GitHub Recovery (Ongoing)

```bash
#!/bin/bash
# scripts/monitor-github-recovery.sh

while true; do
  STATUS=$(curl -s https://www.githubstatus.com/api/v2/status.json | jq -r '.status.indicator')

  if [ "$STATUS" = "none" ]; then
    echo "✅ GitHub is back online!"
    ./scripts/notify-recovery.sh
    break
  fi

  echo "⏳ GitHub still down (status: $STATUS) - checking again in 5 min..."
  sleep 300
done
```

#### Step 5: Sync Back to GitHub (Post-Recovery)

```bash
#!/bin/bash
# scripts/sync-mirrors-to-github.sh

echo "🔄 Syncing local changes back to GitHub..."

for repo in $(cat critical-repos.txt); do
  echo "Syncing: $repo"

  cd "/mirrors/$repo"

  # Reset remote to GitHub
  git remote set-url origin "https://github.com/acme-corp/$repo.git"

  # Push all changes from mirror
  git push origin --all
  git push origin --tags

  # Verify sync
  LOCAL_COMMIT=$(git rev-parse HEAD)
  REMOTE_COMMIT=$(git ls-remote origin HEAD | cut -f1)

  if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    echo "✅ Synced: $repo"
  else
    echo "⚠️  Sync issue: $repo (manual review needed)"
  fi
done

echo "✅ All repositories synced back to GitHub"
```

**Total Recovery Time: N/A (depends on GitHub recovery)**

---

## Recovery Time Objectives

### Summary Table

| Scenario | Detection | Response | Recovery | Total RTO |
|----------|-----------|----------|----------|-----------|
| Repository deletion | < 5 min | 5 min | 10 min | **~20 min** |
| State corruption | < 10 min | 10 min | 10 min | **~30 min** |
| Configuration drift | < 30 min | 15 min | 15 min | **~1 hour** |
| Organization compromise | < 15 min | 30 min | 75 min | **~2 hours** |
| GitHub outage | < 5 min | 10 min | N/A | **Vendor-dependent** |

## Post-Incident Review

### Template

```markdown
# Post-Incident Review: [Incident Title]

**Date:** YYYY-MM-DD
**Incident Commander:** [Name]
**Duration:** [Start] to [End]
**Severity:** P0/P1/P2

## Timeline

- **HH:MM** - Incident detected
- **HH:MM** - Response team assembled
- **HH:MM** - Root cause identified
- **HH:MM** - Recovery initiated
- **HH:MM** - Service restored
- **HH:MM** - Incident closed

## What Happened

[Detailed description of the incident]

## Root Cause

[Technical root cause analysis]

## What Went Well

- ✅ Item 1
- ✅ Item 2

## What Went Wrong

- ❌ Item 1
- ❌ Item 2

## Action Items

- [ ] Action 1 (Owner: [Name], Due: YYYY-MM-DD)
- [ ] Action 2 (Owner: [Name], Due: YYYY-MM-DD)

## Lessons Learned

[Key takeaways for future incidents]
```

---

## Testing Your DR Plan

### Quarterly DR Drill

```bash
#!/bin/bash
# scripts/dr-drill.sh
# Run quarterly disaster recovery drills

echo "🎭 Starting Disaster Recovery Drill..."
echo "This is a SIMULATION - no real changes will be made"

# Simulate state corruption
echo "1️⃣ Simulating state corruption..."
cp terraform.tfstate terraform.tfstate.backup
echo "corrupted" > terraform.tfstate
terraform state pull  # Should fail

# Test restoration
echo "2️⃣ Testing state restoration..."
./scripts/restore-from-backup.sh --simulate

# Simulate repository deletion
echo "3️⃣ Simulating repository deletion..."
# (Use a test repo)
gh repo delete acme-corp/dr-test-repo --yes

# Test recovery
echo "4️⃣ Testing repository recovery..."
terraform apply -target='module.github_governance.github_repository.repo["dr-test-repo"]'

# Verify all DR procedures
echo "5️⃣ Verifying all runbooks..."
./scripts/verify-runbooks.sh

echo "✅ DR Drill completed successfully!"
```

---

**Remember:** The best disaster recovery is preventing disasters in the first place!

- ✅ Use `prevent_destroy` lifecycle rules
- ✅ Automate daily backups
- ✅ Enable audit logging
- ✅ Require code reviews
- ✅ Practice DR procedures regularly
