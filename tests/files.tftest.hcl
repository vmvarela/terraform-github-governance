# Tests for file resources (adapted from modules/repository)
# Tests now use the main module with composite keys (hash-based) for files

mock_provider "github" {}
mock_provider "tls" {}
mock_provider "null" {}
mock_provider "local" {}

variables {
  mode       = "organization"
  name       = "test-org"
  github_org = "test-org"
  settings = {
    billing_email = "billing@test-org.com"
  }
}

# Test 1: Basic file with inline content
run "basic_file_with_content" {
  command = plan

  variables {
    repositories = {
      "file-repo" = {
        description = "Repository with basic file"
        files = [
          {
            file    = "README.md"
            content = "# Test Repository\n\nThis is a test."
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "file-repo/") })) == 1
    error_message = "Should create 1 file"
  }
}

# Test 2: File in specific branch
run "file_in_specific_branch" {
  command = plan

  variables {
    repositories = {
      "branch-file-repo" = {
        description = "Repository with file in specific branch"
        files = [
          {
            file    = "config/development.json"
            content = "{\"env\": \"development\"}"
            branch  = "develop"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "branch-file-repo/") })) == 1
    error_message = "Should create file in specific branch"
  }
}

# Test 3: File with custom commit
run "file_with_custom_commit" {
  command = plan

  variables {
    repositories = {
      "commit-file-repo" = {
        description = "Repository with custom commit file"
        files = [
          {
            file           = "CHANGELOG.md"
            content        = "# Changelog\n\n## v1.0.0"
            commit_message = "docs: Initialize CHANGELOG"
            commit_author  = "Bot User"
            commit_email   = "bot@example.com"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "commit-file-repo/") })) == 1
    error_message = "Should create file with custom commit"
  }
}

# Test 4: Multiple files
run "multiple_files" {
  command = plan

  variables {
    repositories = {
      "multi-file-repo" = {
        description = "Repository with multiple files"
        files = [
          {
            file    = "README.md"
            content = "# Project"
          },
          {
            file    = ".gitignore"
            content = "*.tfstate\n*.tfvars\n.terraform/"
          },
          {
            file    = "LICENSE"
            content = "MIT License"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "multi-file-repo/") })) == 3
    error_message = "Should create 3 files"
  }
}

# Test 5: Complete .gitignore file
run "complete_gitignore_file" {
  command = plan

  variables {
    repositories = {
      "gitignore-repo" = {
        description = "Repository with comprehensive .gitignore"
        files = [
          {
            file           = ".gitignore"
            content        = <<-EOT
              # Terraform
              *.tfstate
              *.tfstate.*
              .terraform/
              .terraform.lock.hcl

              # Variables
              *.tfvars
              *.auto.tfvars

              # IDE
              .idea/
              .vscode/
              *.swp
              *.swo

              # OS
              .DS_Store
              Thumbs.db
            EOT
            commit_message = "chore: Add comprehensive .gitignore"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "gitignore-repo/") })) == 1
    error_message = "Should create .gitignore file"
  }
}

# Test 6: JSON configuration file
run "json_config_file" {
  command = plan

  variables {
    repositories = {
      "json-file-repo" = {
        description = "Repository with JSON config"
        files = [
          {
            file = "config/settings.json"
            content = jsonencode({
              environment = "production"
              debug       = false
              features = {
                api_v2      = true
                maintenance = false
              }
            })
            commit_message = "config: Add production settings"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "json-file-repo/") })) == 1
    error_message = "Should create config file in subdirectory"
  }
}

# Test 7: YAML workflow file
run "yaml_config_file" {
  command = plan

  variables {
    repositories = {
      "yaml-file-repo" = {
        description = "Repository with YAML workflow"
        files = [
          {
            file           = ".github/workflows/ci.yml"
            content        = <<-EOT
              name: CI
              on:
                push:
                  branches: [ main ]
                pull_request:
                  branches: [ main ]
              jobs:
                test:
                  runs-on: ubuntu-latest
                  steps:
                    - uses: actions/checkout@v3
                    - name: Run tests
                      run: echo "Running tests"
            EOT
            commit_message = "ci: Add GitHub Actions workflow"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "yaml-file-repo/") })) == 1
    error_message = "Should create workflow file"
  }
}

# Test 8: Multiple files in different branches
run "files_in_different_branches" {
  command = plan

  variables {
    repositories = {
      "multi-branch-file-repo" = {
        description = "Repository with files in different branches"
        files = [
          {
            file    = "config/production.json"
            content = "{\"env\": \"production\"}"
            branch  = "main"
          },
          {
            file    = "config/development.json"
            content = "{\"env\": \"development\"}"
            branch  = "develop"
          },
          {
            file    = "config/staging.json"
            content = "{\"env\": \"staging\"}"
            branch  = "staging"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "multi-branch-file-repo/") })) == 3
    error_message = "Should create 3 files in different branches"
  }
}

# Test 9: Complete README file
run "complete_readme_file" {
  command = plan

  variables {
    repositories = {
      "readme-repo" = {
        description = "Repository with comprehensive README"
        files = [
          {
            file           = "README.md"
            content        = <<-EOT
              # Terraform GitHub Repository Module

              This module manages GitHub repositories.

              ## Features

              - Repository creation and configuration
              - Branch protection rules
              - Webhooks management
              - Secrets and variables

              ## Usage

              ```hcl
              module "repository" {
                source = "./modules/repository"
                name   = "my-repo"
              }
              ```

              ## License

              MIT
            EOT
            commit_message = "docs: Add comprehensive README"
            commit_author  = "Documentation Bot"
            commit_email   = "docs@example.com"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "readme-repo/") })) == 1
    error_message = "Should create README.md"
  }
}

# Test 10: License file
run "license_file" {
  command = plan

  variables {
    repositories = {
      "license-repo" = {
        description = "Repository with LICENSE"
        files = [
          {
            file           = "LICENSE"
            content        = <<-EOT
              MIT License

              Copyright (c) 2024 Example Organization

              Permission is hereby granted, free of charge...
            EOT
            commit_message = "chore: Add MIT license"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "license-repo/") })) == 1
    error_message = "Should create LICENSE file"
  }
}

# Test 11: File with overwrite option
run "file_with_overwrite" {
  command = plan

  variables {
    repositories = {
      "overwrite-repo" = {
        description = "Repository with overwrite file"
        files = [
          {
            file                = "config.json"
            content             = "{\"version\": \"2.0\"}"
            overwrite_on_create = true
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "overwrite-repo/") })) == 1
    error_message = "Should create file with overwrite option"
  }
}

# Test 12: Documentation files
run "documentation_files" {
  command = plan

  variables {
    repositories = {
      "docs-repo" = {
        description = "Repository with documentation files"
        files = [
          {
            file    = "docs/CONTRIBUTING.md"
            content = "# Contributing Guide"
          },
          {
            file    = "docs/CODE_OF_CONDUCT.md"
            content = "# Code of Conduct"
          },
          {
            file    = "docs/SECURITY.md"
            content = "# Security Policy"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "docs-repo/") })) == 3
    error_message = "Should create 3 documentation files"
  }
}

# Test 13: GitHub issue template
run "github_issue_template" {
  command = plan

  variables {
    repositories = {
      "template-repo" = {
        description = "Repository with issue template"
        files = [
          {
            file    = ".github/ISSUE_TEMPLATE/bug_report.md"
            content = <<-EOT
              ---
              name: Bug Report
              about: Create a report to help us improve
              title: '[BUG] '
              labels: bug
              assignees: ''
              ---

              ## Describe the bug
              A clear and concise description of what the bug is.
            EOT
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "template-repo/") })) == 1
    error_message = "Should create issue template"
  }
}

# Test 14: Dynamically generated files
run "dynamically_generated_files" {
  command = plan

  variables {
    repositories = {
      "generated-repo" = {
        description = "Repository with generated files"
        files = [
          {
            file    = "VERSION"
            content = "1.0.0"
          },
          {
            file    = "BUILD_INFO"
            content = "Build: ${timestamp()}"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys({ for k, v in github_repository_file.repo : k => v if startswith(k, "generated-repo/") })) == 2
    error_message = "Should create 2 generated files"
  }
}

# Test 15: Multiple repositories with files
run "multiple_repos_with_files" {
  command = plan

  variables {
    repositories = {
      "repo-a" = {
        description = "First repository"
        files = [
          {
            file    = "README.md"
            content = "# Repository A"
          }
        ]
      }
      "repo-b" = {
        description = "Second repository"
        files = [
          {
            file    = "README.md"
            content = "# Repository B"
          }
        ]
      }
    }
  }

  assert {
    condition     = length(keys(github_repository_file.repo)) == 2
    error_message = "Should create 2 files across 2 repositories"
  }
}
