# Global User Permission Optimization

## Overview

The module automatically optimizes global user permissions when multiple users share the same role. Instead of creating individual collaborator assignments for each user, the module creates a team (project mode) or uses organization roles (organization mode) to manage permissions centrally.

## How It Works

### Scope

**IMPORTANT**: This optimization **ONLY** applies to global users defined in `var.users` (or `settings.users`). Repository-specific users defined within individual repository configurations are NOT affected and continue to be managed as individual collaborators.

### Detection

The module automatically detects when 2 or more global users share the same role:

```hcl
users = {
  "alice"   = "maintain"
  "bob"     = "maintain"  # 2+ users with "maintain" role
  "charlie" = "maintain"  # -> triggers optimization
  "david"   = "admin"     # Only 1 user with "admin" -> no optimization
}
```

### Optimization Strategy

#### Project Mode (`var.mode = "project"`)

When 2+ global users share a role, the module:

1. **Creates a team** with name `<project-name>-<role>`
   - Example: `my-project-maintain`
   - Privacy: `closed`

2. **Adds users to the team** via `github_team_membership`
   - All users with the shared role become team members

3. **Assigns the team** to all repositories
   - Replaces individual user collaborator assignments
   - Uses the original role permission level

**Benefits**:
- Reduces the number of `github_repository_collaborators` resources
- Centralizes permission management
- Easier to add/remove users from the role
- Better audit trail (team membership changes)

#### Organization Mode (`var.mode = "organization"`)

When 2+ global users share a role, the module:

1. **Uses existing organization roles** defined in `var.organization_roles`
2. **Assigns users** via `github_organization_role_user` (already in `organization.tf`)
3. **Repository permissions** are inherited from the organization role

**Note**: Organization-wide roles are already centralized, so this mode doesn't create additional resources. Users continue to be assigned at the repository level but with consistent role definitions.

## Example Usage

### Project Mode Example

```hcl
module "governance" {
  source = "../../"

  mode = "project"
  name = "my-awesome-project"

  # Global users - will be optimized
  users = {
    "alice"   = "maintain"
    "bob"     = "maintain"
    "charlie" = "maintain"
    "david"   = "admin"
    "eve"     = "admin"
  }

  repositories = {
    "repo-1" = {
      description = "First repository"
      # No users defined here - will inherit optimized global users
    }
    "repo-2" = {
      description = "Second repository"
      # Repository-specific user - NOT optimized
      users = {
        "frank" = "write"
      }
    }
  }
}
```

**Result**:
- Team `my-awesome-project-maintain` created with alice, bob, charlie
- Team `my-awesome-project-admin` created with david, eve
- Both teams assigned to repo-1 and repo-2
- Frank remains as individual collaborator on repo-2 only

### Organization Mode Example

```hcl
module "governance" {
  source = "../../"

  mode         = "organization"
  name         = "my-org"
  github_token = var.github_token

  # Global users - will use organization roles
  users = {
    "alice"   = "maintain"
    "bob"     = "maintain"
    "charlie" = "maintain"
  }

  # Define organization-wide roles
  organization_roles = {
    "maintain-role" = {
      name        = "Maintainer"
      description = "Can maintain repositories"
      base_role   = "maintain"
      permissions = []
    }
  }

  repositories = {
    "repo-1" = {
      description = "Organization repository"
    }
  }
}
```

## Technical Implementation

### Data Flow

```
var.users (global)
  ↓
merge with settings.users
  ↓
local.settings.users
  ↓
local.global_users_by_role (groups by role)
  ↓
local.optimizable_global_roles (filter: 2+ users)
  ↓
local.optimized_role_names (generate team/role names)
  ↓
PROJECT MODE: github_team.global_role_teams
ORGANIZATION MODE: (no additional resources)
  ↓
local.repositories_optimized (replace users with teams)
  ↓
github_repository_collaborators.repo (uses optimized config)
```

### Key Locals

- **`local.global_users_by_role`**: Groups global users by their role
  ```hcl
  {
    "maintain" = ["alice", "bob", "charlie"]
    "admin"    = ["david", "eve"]
  }
  ```

- **`local.optimizable_global_roles`**: Filters roles with 2+ users
  ```hcl
  {
    "maintain" = ["alice", "bob", "charlie"]
    "admin"    = ["david", "eve"]
  }
  ```

- **`local.optimized_role_names`**: Team/role names by mode
  ```hcl
  # Project mode:
  {
    "maintain" = "my-project-maintain"
    "admin"    = "my-project-admin"
  }

  # Organization mode:
  {
    "maintain" = "auto-maintain"
    "admin"    = "auto-admin"
  }
  ```

- **`local.repositories_optimized`**: Modified repository config
  ```hcl
  # Before optimization:
  {
    "repo-1" = {
      users = {
        "alice"   = "maintain"
        "bob"     = "maintain"
        "charlie" = "maintain"
      }
      teams = {}
    }
  }

  # After optimization (project mode):
  {
    "repo-1" = {
      users = {}  # Global users removed
      teams = {
        "<team-id>" = "maintain"  # Team added
      }
    }
  }
  ```

### Resources Created (Project Mode)

1. **`github_team.global_role_teams`**
   - One team per optimizable role
   - Name: `<var.name>-<role>`
   - Privacy: `closed`

2. **`github_team_membership.global_role_members`**
   - One membership per user per team
   - Role: `member` (team role, not repository permission)

3. **`github_repository_collaborators.repo`**
   - Uses `local.repositories_optimized`
   - Teams assigned instead of individual users

## Benefits

### Performance
- **Fewer API calls**: 1 team assignment vs N user assignments per repository
- **Faster apply**: Less resources to create/update
- **Better scaling**: O(1) team + O(N) memberships vs O(N×R) collaborators

### Maintainability
- **Central management**: Add/remove users from team, not each repository
- **Consistency**: Same permission level across all repositories
- **Audit trail**: Team membership changes are tracked
- **Easier refactoring**: Move users between roles without touching repositories

### Cost (for large setups)
- **API rate limits**: Fewer GitHub API calls
- **Terraform state**: Smaller state file
- **Plan/apply time**: Faster operations

## Comparison

### Without Optimization

```
3 users × 10 repositories = 30 github_repository_collaborators resources
```

### With Optimization (Project Mode)

```
1 github_team
+ 3 github_team_membership
+ 10 repository team assignments (within github_repository_collaborators)
= 14 resources
```

**Savings**: 16 fewer resources (53% reduction)

## Limitations

1. **Only global users**: Repository-specific users are NOT optimized
2. **Minimum 2 users**: Single-user roles remain as individual collaborators
3. **Project mode only creates teams**: Organization mode relies on existing role infrastructure
4. **Team naming convention**: Teams are auto-named as `<project>-<role>`, cannot be customized

## Troubleshooting

### Team Already Exists

If a team with the auto-generated name already exists, Terraform will fail. Solutions:

1. **Rename existing team**: Change the name to avoid conflict
2. **Import existing team**: Use `terraform import` to bring it under management
3. **Change project name**: Use a different `var.name` to generate unique team names

### Users Not Being Optimized

Check:
1. Users are defined in `var.users` (global), not in repository-specific `users`
2. At least 2 users share the same role
3. Mode is `project` (organization mode doesn't create new teams)

### Team Permissions Not Working

Verify:
1. Team has correct permission level in `local.repositories_optimized`
2. Team membership is created (`github_team_membership`)
3. Repository collaborators resource uses `local.repositories_optimized`

## Future Enhancements

Potential improvements for this feature:

1. **Custom team names**: Allow overriding the auto-generated team names
2. **Organization mode teams**: Create organization-level teams instead of using roles
3. **Threshold configuration**: Make the "2+ users" threshold configurable
4. **Opt-out mechanism**: Add flag to disable optimization per role or globally
5. **Mixed mode**: Optimize some roles while keeping others as individual collaborators

## Related Documentation

- [Organization Roles](ORGANIZATION_ROLES.md) - Organization-wide role management
- [File Structure](REFACTORING_ORGANIZATION.md) - Module structure and organization
- [Variables](../variables.tf) - Input variable definitions
- [Outputs](../outputs.tf) - Module outputs including team information
