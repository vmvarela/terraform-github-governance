terraform {
  required_version = ">= 1.6"

  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.6.0"
    }
  }
}

resource "github_repository_file" "this" {
  repository                      = var.repository
  file                            = var.file
  content                         = var.from_file != null ? file(var.from_file) : var.content
  branch                          = var.branch
  commit_author                   = var.commit_author
  commit_email                    = var.commit_email
  commit_message                  = var.commit_message
  overwrite_on_create             = var.overwrite_on_create
  autocreate_branch               = var.autocreate_branch
  autocreate_branch_source_branch = var.autocreate_branch_source_branch
  autocreate_branch_source_sha    = var.autocreate_branch_source_sha
}
