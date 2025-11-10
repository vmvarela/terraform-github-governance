terraform {
  required_version = ">= 1.6"

  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.6.0"
    }
  }
}

locals {
  repository_roles = {
    "maintain" = 2
    "write"    = 4
    "admin"    = 5
  }
}


# repository_ruleset
resource "github_repository_ruleset" "this" {
  repository  = var.repository
  name        = var.name
  enforcement = var.enforcement
  target      = var.target

  dynamic "conditions" {
    for_each = (length(var.include) + length(var.exclude) > 0) ? [1] : []
    content {
      ref_name {
        include = [for p in var.include :
          substr(p, 0, 1) == "~" ? p : format("refs/%s/%s", var.target == "branch" ? "heads" : "tags", p)
        ]
        exclude = [for p in var.exclude :
          substr(p, 0, 1) == "~" ? p : format("refs/%s/%s", var.target == "branch" ? "heads" : "tags", p)
        ]
      }
    }
  }

  dynamic "bypass_actors" {
    for_each = var.bypass_roles
    content {
      actor_type  = "RepositoryRole"
      actor_id    = lookup(local.repository_roles, bypass_actors.value, null)
      bypass_mode = var.bypass_mode
    }
  }
  dynamic "bypass_actors" {
    for_each = var.bypass_teams
    content {
      actor_type  = "Team"
      actor_id    = bypass_actors.value
      bypass_mode = var.bypass_mode
    }
  }
  dynamic "bypass_actors" {
    for_each = var.bypass_integration
    content {
      actor_type  = "Integration"
      actor_id    = bypass_actors.value
      bypass_mode = var.bypass_mode
    }
  }
  dynamic "bypass_actors" {
    for_each = var.bypass_organization_admin == true ? [1] : []
    content {
      actor_type  = "OrganizationAdmin"
      actor_id    = 0 # admin
      bypass_mode = var.bypass_mode
    }
  }

  rules {
    dynamic "branch_name_pattern" {
      for_each = var.target == "branch" && var.regex_target != null ? [1] : []
      content {
        operator = "regex"
        pattern  = var.regex_target
      }
    }
    dynamic "tag_name_pattern" {
      for_each = var.target == "tag" && var.regex_target != null ? [1] : []
      content {
        operator = "regex"
        pattern  = var.regex_target
      }
    }
    dynamic "commit_author_email_pattern" {
      for_each = var.regex_commit_author_email != null ? [1] : []
      content {
        operator = "regex"
        pattern  = var.regex_commit_author_email
      }
    }
    dynamic "commit_message_pattern" {
      for_each = var.regex_commit_message != null ? [1] : []
      content {
        operator = "regex"
        pattern  = var.regex_commit_message
      }
    }
    dynamic "committer_email_pattern" {
      for_each = var.regex_committer_email != null ? [1] : []
      content {
        operator = "regex"
        pattern  = var.regex_committer_email
      }
    }

    creation         = var.forbidden_creation
    deletion         = var.forbidden_deletion
    update           = var.forbidden_update
    non_fast_forward = var.forbidden_fast_forward

    dynamic "pull_request" {
      for_each = (
        var.dismiss_pr_stale_reviews_on_push != null ||
        var.required_pr_code_owner_review != null ||
        var.required_pr_last_push_approval != null ||
        var.required_pr_approving_review_count != null ||
        var.required_pr_review_thread_resolution != null
      ) ? [1] : []
      content {
        dismiss_stale_reviews_on_push     = var.dismiss_pr_stale_reviews_on_push
        require_code_owner_review         = var.required_pr_code_owner_review
        require_last_push_approval        = var.required_pr_last_push_approval
        required_approving_review_count   = var.required_pr_approving_review_count
        required_review_thread_resolution = var.required_pr_review_thread_resolution
      }
    }
    dynamic "required_deployments" {
      for_each = var.required_deployment_environments != null && length(var.required_deployment_environments) > 0 ? [1] : []
      content {
        required_deployment_environments = var.required_deployment_environments
      }
    }
    required_linear_history = var.required_linear_history
    required_signatures     = var.required_signatures
    dynamic "required_status_checks" {
      for_each = var.required_checks != null && length(var.required_checks) > 0 ? [1] : []
      content {
        dynamic "required_check" {
          for_each = var.required_checks
          content {
            context = required_check.value
          }
        }
      }
    }
    dynamic "required_code_scanning" {
      for_each = length(var.required_code_scanning) > 0 ? [1] : []
      content {
        dynamic "required_code_scanning_tool" {
          for_each = var.required_code_scanning
          content {
            tool                      = required_code_scanning_tool.key
            security_alerts_threshold = try(split(":", required_code_scanning_tool.value)[0], "none")
            alerts_threshold          = try(split(":", required_code_scanning_tool.value)[1], "none")
          }
        }
      }
    }
  }
}
