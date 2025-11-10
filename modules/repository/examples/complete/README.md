# Complete Repository Example

This example demonstrates a comprehensive GitHub repository configuration showcasing all features available in this Terraform module.

## Features Demonstrated

### Repository Settings
- Private repository with custom visibility
- Homepage URL configuration
- Repository features (issues, wiki, projects)
- Topics for better discoverability

### Security Configuration
- GitHub Advanced Security enabled
- Secret scanning with push protection
- Vulnerability alerts
- Dependabot security updates
- Required code scanning in rulesets

### GitHub Actions
- Custom access level and allowed actions policy
- Actions secrets and variables management
- Verified creators allowed
- Specific action patterns configured

### Branch Management
- Multiple branches (develop, staging, production)
- Branch protection via rulesets
- Different protection levels per branch
- Required reviews and status checks

### Merge Strategy
- Multiple merge methods configured
- Auto-merge enabled
- Automatic branch deletion
- Custom commit titles and messages

### Deploy Keys
- Auto-generated SSH keys for CI/CD
- Separate keys for different purposes
- Read-only and write access configurations

### Collaboration
- User and team permissions
- Multiple permission levels
- Issue labels with custom colors
- Autolink references for external systems

### Environments
- Multiple deployment environments (dev, staging, production)
- Environment-specific variables and secrets
- Deployment protection rules
- Review requirements per environment
- Wait timers for production deployments

### Repository Files
- Automated file management
- .gitignore configuration
- Contributing guidelines
- Custom commit messages

### Webhooks
- Multiple webhook configurations
- Different event subscriptions
- Secure webhook secrets
- JSON and form content types

### Rulesets
- Main branch protection with strict rules
- Tag protection for releases
- Feature branch naming conventions
- Required code reviews
- Required status checks
- Code scanning requirements
- Commit signature requirements
- Linear history enforcement

## Usage

1. Set your GitHub token:
   ```bash
   export GITHUB_TOKEN="your_github_token"
   ```

2. Customize the variables in `main.tf` according to your needs:
   - Repository name
   - User and team collaborators
   - Environment configurations
   - Webhook URLs
   - Autolink reference URLs

3. Initialize and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Review the outputs to get repository information and deploy keys

5. Clean up when done:
   ```bash
   terraform destroy
   ```

## Notes

- The deploy keys are auto-generated and stored in Terraform state
- Secrets are stored in plain text in this example; consider using encrypted values in production
- Adjust the ruleset configurations based on your team's workflow
- Some features like Advanced Security require a GitHub Enterprise or organization plan

## Outputs

- `repository_name`: The name of the created repository
- `repository_full_name`: Full repository name (owner/name)
- `repository_html_url`: GitHub web URL
- `repository_ssh_clone_url`: SSH clone URL
- `repository_http_clone_url`: HTTPS clone URL
- `deploy_keys`: Auto-generated private keys (sensitive)
