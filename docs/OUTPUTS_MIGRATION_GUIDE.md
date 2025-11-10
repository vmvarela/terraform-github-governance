# 📤 Outputs Migration Guide

## Overview

This guide helps users migrate from the legacy single `repository` output to the new granular outputs introduced in the latest version.

## What Changed?

### Before (Legacy)
```hcl
module "my_repo" {
  source = "./modules/repository"
  # ... configuration ...
}

# Accessing repository data required navigating nested structures
output "repo_url" {
  value = module.my_repo.repository.html_url
}

output "repo_id" {
  value = module.my_repo.repository.repo_id
}
```

### After (New Granular Outputs)
```hcl
module "my_repo" {
  source = "./modules/repository"
  # ... configuration ...
}

# Direct access to specific attributes
output "repo_url" {
  value = module.my_repo.repository_url
}

output "repo_id" {
  value = module.my_repo.repository_id
}
```

## Benefits

✅ **Better Performance**: Terraform can build dependency graphs more efficiently  
✅ **Cleaner Code**: No need to navigate nested object structures  
✅ **Better Documentation**: Each output has clear description in terraform-docs  
✅ **Type Safety**: Individual outputs have explicit types  
✅ **Backwards Compatible**: Legacy `repository` output still available

## Available Outputs

### Basic Repository Attributes
- `repository_id` - Numeric ID
- `repository_name` - Repository name
- `repository_full_name` - Full name (owner/repo)
- `repository_url` - GitHub URL
- `repository_git_clone_url` - HTTPS clone URL
- `repository_ssh_clone_url` - SSH clone URL
- `default_branch` - Default branch name
- `visibility` - public/private/internal
- `topics` - List of topics
- `homepage_url` - Homepage URL
- `is_template` - Template flag
- `archived` - Archive status

### Configuration Objects
- `security_configuration` - All security features in one object
- `merge_configuration` - All merge settings in one object
- `features_enabled` - All repository features in one object

### Submodules
- `environments` - Map of environment configurations
- `webhooks` - Map of webhook configurations
- `rulesets` - Map of ruleset configurations
- `deploy_keys` - Map of deploy key configurations

## Migration Examples

### Example 1: Basic Repository Info

**Before:**
```hcl
output "repos_info" {
  value = {
    for k, repo in module.repos : k => {
      url  = repo.repository.html_url
      name = repo.repository.name
      id   = repo.repository.repo_id
    }
  }
}
```

**After:**
```hcl
output "repos_info" {
  value = {
    for k, repo in module.repos : k => {
      url  = repo.repository_url
      name = repo.repository_name
      id   = repo.repository_id
    }
  }
}
```

### Example 2: Security Posture Dashboard

**Before:**
```hcl
output "security_status" {
  value = {
    for k, repo in module.repos : k => {
      advanced_security = try(
        repo.repository.security_and_analysis[0].advanced_security[0].status == "enabled",
        false
      )
      secret_scanning = try(
        repo.repository.security_and_analysis[0].secret_scanning[0].status == "enabled",
        false
      )
      # ... more nested access ...
    }
  }
}
```

**After:**
```hcl
output "security_status" {
  value = {
    for k, repo in module.repos : k => repo.security_configuration
  }
}
```

### Example 3: Clone URLs Collection

**Before:**
```hcl
output "clone_urls" {
  value = {
    for k, repo in module.repos : k => {
      https = repo.repository.http_clone_url
      ssh   = repo.repository.ssh_clone_url
    }
  }
}
```

**After:**
```hcl
output "clone_urls" {
  value = {
    for k, repo in module.repos : k => {
      https = repo.repository_git_clone_url
      ssh   = repo.repository_ssh_clone_url
    }
  }
}
```

## Backwards Compatibility

The legacy `repository` output is **still available** and will not be removed. You can migrate at your own pace.

```hcl
# ✅ Still works - legacy output
output "repo" {
  value = module.my_repo.repository
}

# ✅ New approach - granular outputs
output "repo_url" {
  value = module.my_repo.repository_url
}
```

## Best Practices

1. **Use granular outputs** for new code
2. **Migrate incrementally** - no rush, backwards compatibility maintained
3. **Leverage configuration objects** (`security_configuration`, `merge_configuration`) for grouped data
4. **Reference documentation** - `terraform-docs` now shows all available outputs

## Need Help?

- Check `modules/repository/outputs.tf` for complete list
- Run `terraform-docs` to see output documentation
- Review examples in `examples/` directory

---

**Note:** This migration is **optional**. The module maintains full backwards compatibility.
