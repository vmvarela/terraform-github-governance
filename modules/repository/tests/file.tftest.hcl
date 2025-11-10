# Tests for file module with mock providers

mock_provider "github" {}

variables {
  name       = "test-file-repo"
  visibility = "public"
}

# Test 1: Basic file with inline content
run "basic_file_with_content" {
  command = plan

  variables {
    files = [
      {
        file    = "README.md"
        content = "# Test Repository\n\nThis is a test."
      }
    ]
  }

  assert {
    condition     = length(keys(module.file)) == 1
    error_message = "Should create 1 file"
  }
}

# Test 2: File from external source (skipped - requires actual file)
# This test would require actual file in filesystem
# run "file_from_external_file" {
#   ...
# }

# Test 3: File in specific branch
run "file_in_specific_branch" {
  command = plan

  variables {
    default_branch = "main"
    branches = {
      "develop" = "main"
    }
    files = [
      {
        file    = "config/development.json"
        content = "{\"env\": \"development\"}"
        branch  = "develop"
      }
    ]
  }

  assert {
    condition     = length(keys(module.file)) == 1
    error_message = "Should create file in specific branch"
  }
}

# Test 4: Archivo con commit personalizado
run "file_with_custom_commit" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.file)) == 1
    error_message = "Should create file with custom commit"
  }
}

# Test 5: Multiple files
run "multiple_files" {
  command = plan

  variables {
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

  assert {
    condition     = length(module.file) == 3
    error_message = "Should create 3 files"
  }
}

# Test 6: Archivo .gitignore completo
run "complete_gitignore_file" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.file)) == 1
    error_message = "Should create .gitignore file"
  }
}

# Test 7: JSON configuration file
run "json_config_file" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.file)) == 1
    error_message = "Should create config file in subdirectory"
  }
}

# Test 8: Archivo YAML
run "yaml_config_file" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.file)) == 1
    error_message = "Should create workflow file"
  }
}

# Test 9: Multiple files in different branches
run "files_in_different_branches" {
  command = plan

  variables {
    default_branch = "main"
    branches = {
      "develop" = "main"
      "staging" = "main"
    }
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

  assert {
    condition     = length(module.file) == 3
    error_message = "Should create 3 files in different branches"
  }
}

# Test 10: Archivo README completo
run "complete_readme_file" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.file)) == 1
    error_message = "Should create README.md"
  }
}

# Test 11: Archivo de licencia
run "license_file" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.file)) == 1
    error_message = "Should create LICENSE file"
  }
}

# Test 12: Archivo con overwrite
run "file_with_overwrite" {
  command = plan

  variables {
    files = [
      {
        file                = "config.json"
        content             = "{\"version\": \"2.0\"}"
        overwrite_on_create = true
      }
    ]
  }

  assert {
    condition     = length(keys(module.file)) == 1
    error_message = "Should create file with overwrite option"
  }
}

# Test 13: Documentation files
run "documentation_files" {
  command = plan

  variables {
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

  assert {
    condition     = length(module.file) == 3
    error_message = "Should create 3 documentation files"
  }
}

# Test 14: Archivo de GitHub issue template
run "github_issue_template" {
  command = plan

  variables {
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

  assert {
    condition     = length(keys(module.file)) == 1
    error_message = "Should create issue template"
  }
}

# Test 15: Dynamically generated file
run "dynamically_generated_file" {
  command = plan

  variables {
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

  assert {
    condition     = length(module.file) == 2
    error_message = "Should create 2 generated files"
  }
}
