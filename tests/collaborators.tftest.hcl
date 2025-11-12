# Tests for Repository Collaborators
# Covers: github_repository_collaborators resource

mock_provider "github" {}
mock_provider "tls" {}
mock_provider "null" {}
mock_provider "local" {}

variables {
  name       = "test-org"
  github_org = "test-org"
}

override_data {
  target = data.github_organization.this[0]
  values = {
    plan = "enterprise"
  }
}

override_data {
  target = data.github_repositories.all[0]
  values = {
    names = []
  }
}

# Test 1: Basic team collaborators
run "basic_team_collaborators" {
  command = plan

  variables {
    repositories = {
      "team-repo" = {
        description = "Repository with team collaborators"
        teams = {
          "developers" = "push"
          "reviewers"  = "pull"
        }
      }
    }
  }

  assert {
    condition     = length(github_repository_collaborators.repo["team-repo"].team) == 2
    error_message = "Should have 2 team collaborators"
  }

  assert {
    condition = anytrue([
      for t in github_repository_collaborators.repo["team-repo"].team :
      t.team_id == "developers" && t.permission == "push"
    ])
    error_message = "Should have developers team with push permission"
  }

  assert {
    condition = anytrue([
      for t in github_repository_collaborators.repo["team-repo"].team :
      t.team_id == "reviewers" && t.permission == "pull"
    ])
    error_message = "Should have reviewers team with pull permission"
  }
}

# Test 2: Basic user collaborators
run "basic_user_collaborators" {
  command = plan

  variables {
    repositories = {
      "user-repo" = {
        description = "Repository with user collaborators"
        users = {
          "alice" = "admin"
          "bob"   = "write"
          "carol" = "read"
        }
      }
    }
  }

  assert {
    condition     = length(github_repository_collaborators.repo["user-repo"].user) == 3
    error_message = "Should have 3 user collaborators"
  }

  assert {
    condition = anytrue([
      for u in github_repository_collaborators.repo["user-repo"].user :
      u.username == "alice" && u.permission == "admin"
    ])
    error_message = "Should have alice with admin permission"
  }

  assert {
    condition = anytrue([
      for u in github_repository_collaborators.repo["user-repo"].user :
      u.username == "bob" && u.permission == "write"
    ])
    error_message = "Should have bob with write permission"
  }

  assert {
    condition = anytrue([
      for u in github_repository_collaborators.repo["user-repo"].user :
      u.username == "carol" && u.permission == "read"
    ])
    error_message = "Should have carol with read permission"
  }
}

# Test 3: Mixed teams and users
run "mixed_collaborators" {
  command = plan

  variables {
    repositories = {
      "mixed-repo" = {
        description = "Repository with both teams and users"
        teams = {
          "backend-team"  = "maintain"
          "frontend-team" = "write"
        }
        users = {
          "tech-lead" = "admin"
          "intern"    = "read"
        }
      }
    }
  }

  assert {
    condition     = length(github_repository_collaborators.repo["mixed-repo"].team) == 2
    error_message = "Should have 2 team collaborators"
  }

  assert {
    condition     = length(github_repository_collaborators.repo["mixed-repo"].user) == 2
    error_message = "Should have 2 user collaborators"
  }

  assert {
    condition = anytrue([
      for t in github_repository_collaborators.repo["mixed-repo"].team :
      t.team_id == "backend-team" && t.permission == "maintain"
    ])
    error_message = "Should have backend-team with maintain permission"
  }

  assert {
    condition = anytrue([
      for u in github_repository_collaborators.repo["mixed-repo"].user :
      u.username == "tech-lead" && u.permission == "admin"
    ])
    error_message = "Should have tech-lead with admin permission"
  }
}

# Test 7: Repository without collaborators
run "repository_without_collaborators" {
  command = plan

  variables {
    repositories = {
      "no-collab-repo" = {
        description = "Repository without explicit collaborators"
      }
    }
  }

  assert {
    condition     = length(github_repository_collaborators.repo["no-collab-repo"].team) == 0
    error_message = "Should have no team collaborators"
  }

  assert {
    condition     = length(github_repository_collaborators.repo["no-collab-repo"].user) == 0
    error_message = "Should have no user collaborators"
  }
}

# Test 8: All permission levels for teams
run "all_team_permission_levels" {
  command = plan

  variables {
    repositories = {
      "permissions-repo" = {
        description = "Repository with all team permission levels"
        teams = {
          "team-pull"     = "pull"
          "team-triage"   = "triage"
          "team-push"     = "push"
          "team-maintain" = "maintain"
          "team-admin"    = "admin"
        }
      }
    }
  }

  assert {
    condition     = length(github_repository_collaborators.repo["permissions-repo"].team) == 5
    error_message = "Should have 5 teams with different permissions"
  }

  assert {
    condition = alltrue([
      anytrue([for t in github_repository_collaborators.repo["permissions-repo"].team : t.permission == "pull"]),
      anytrue([for t in github_repository_collaborators.repo["permissions-repo"].team : t.permission == "triage"]),
      anytrue([for t in github_repository_collaborators.repo["permissions-repo"].team : t.permission == "push"]),
      anytrue([for t in github_repository_collaborators.repo["permissions-repo"].team : t.permission == "maintain"]),
      anytrue([for t in github_repository_collaborators.repo["permissions-repo"].team : t.permission == "admin"])
    ])
    error_message = "Should have all 5 permission levels represented"
  }
}

# Test 9: All permission levels for users
run "all_user_permission_levels" {
  command = plan

  variables {
    repositories = {
      "user-permissions-repo" = {
        description = "Repository with all user permission levels"
        users = {
          "user-pull"     = "pull"
          "user-triage"   = "triage"
          "user-push"     = "push"
          "user-maintain" = "maintain"
          "user-admin"    = "admin"
        }
      }
    }
  }

  assert {
    condition     = length(github_repository_collaborators.repo["user-permissions-repo"].user) == 5
    error_message = "Should have 5 users with different permissions"
  }

  assert {
    condition = alltrue([
      anytrue([for u in github_repository_collaborators.repo["user-permissions-repo"].user : u.permission == "pull"]),
      anytrue([for u in github_repository_collaborators.repo["user-permissions-repo"].user : u.permission == "triage"]),
      anytrue([for u in github_repository_collaborators.repo["user-permissions-repo"].user : u.permission == "push"]),
      anytrue([for u in github_repository_collaborators.repo["user-permissions-repo"].user : u.permission == "maintain"]),
      anytrue([for u in github_repository_collaborators.repo["user-permissions-repo"].user : u.permission == "admin"])
    ])
    error_message = "Should have all 5 permission levels represented"
  }
}

# Test 10: Multiple repositories with different collaborators
run "multiple_repositories_different_collaborators" {
  command = plan

  variables {
    repositories = {
      "frontend-repo" = {
        description = "Frontend repository"
        teams = {
          "frontend-team" = "maintain"
        }
      }
      "backend-repo" = {
        description = "Backend repository"
        teams = {
          "backend-team" = "maintain"
        }
      }
      "infra-repo" = {
        description = "Infrastructure repository"
        teams = {
          "sre-team" = "admin"
        }
        users = {
          "infra-lead" = "admin"
        }
      }
    }
  }

  assert {
    condition     = length(keys(github_repository_collaborators.repo)) == 3
    error_message = "Should create collaborators for 3 repositories"
  }

  assert {
    condition     = length(github_repository_collaborators.repo["frontend-repo"].team) == 1
    error_message = "Frontend repo should have 1 team"
  }

  assert {
    condition     = length(github_repository_collaborators.repo["backend-repo"].team) == 1
    error_message = "Backend repo should have 1 team"
  }

  assert {
    condition     = length(github_repository_collaborators.repo["infra-repo"].team) == 1
    error_message = "Infra repo should have 1 team"
  }

  assert {
    condition     = length(github_repository_collaborators.repo["infra-repo"].user) == 1
    error_message = "Infra repo should have 1 user"
  }
}
