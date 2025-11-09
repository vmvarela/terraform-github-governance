terraform {
  required_version = ">= 1"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = var.name
  token = var.github_token
}

module "github" {
  source      = "../../"
  mode        = "organization"
  name        = var.name
  description = var.description
  runner_groups = {
    "myrunnergroup" = { allow_public_repositories = true }
  }
  # repository_roles = {
  #   "myrole" = {
  #     description = "My custom role"
  #     base_role   = "write"
  #     permissions = ["remove_assignee"]
  #   }
  # }
  webhooks = {
    "mywebhook" = {
      url          = "https://www.mycompany.com/webhook"
      content_type = "json"
      events       = ["issues"]
    }
  }
  variables = {
    "SHARED_VAR" = "SHARED_VALUE"
  }
  settings = {
    billing_email = var.billing_email
    variables = {
      MYVAR = "MYVAL"
    }
  }
  repositories = {
    "repo-1" = {
      description = "First repository"
      visibility  = "private"
    }
    "repo-2" = {
      description = "Second repository"
      visibility  = "public"
    }
  }
}

module "project" {
  source      = "../../"
  mode        = "project"
  name        = "project-x"
  description = "Project X description"
  github_org  = var.name
  spec        = "x-%s"
  runner_groups = {
    "self-hosted" = {}
  }
  variables = {
    "SHARED_VAR" = "SHARED_VALUE"
  }
  secrets = {
    "SHARED_SECRET" = "xxx"
  }
  # rulesets = {
  #   test = {
  #     target  = "branch"
  #     include = ["~ALL"]
  #     required_workflows = [
  #       "test-1/.github/workflows/test.yaml"
  #     ]
  #     forbidden_deletion = true
  #   }
  # }
  dependabot_copy_secrets = true
  settings = {
    variables = {
      MYVAR = "MYPROJECTVAL"
    }
  }
  repositories = {
    "repo-1" = {
      description = "First repository"
      visibility  = "private"
    }
    "repo-2" = {
      description = "Second repository"
      visibility  = "public"
    }
  }
}
