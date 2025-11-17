terraform {
  required_version = ">= 1.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.8.1"
    }
  }
}

provider "github" {
  owner = var.organization
  token = var.github_token
}

# Data sources to resolve team/user/app IDs
# Note: In production, the parent governance module handles this centrally
data "github_team" "sre" {
  slug = "sre"
}

data "github_team" "developers" {
  slug = "developers"
}

data "github_team" "security_ops" {
  slug = "security-ops"
}

locals {
  # Build ID maps from data sources
  github_team_ids = {
    sre          = data.github_team.sre.id
    developers   = data.github_team.developers.id
    security-ops = data.github_team.security_ops.id
  }

  github_user_ids = {} # Add users if needed
  github_app_ids  = {} # Add apps if needed
}

# Example: Production repository with comprehensive configuration
module "production_api" {
  source = "../../"

  name           = "production-api"
  organization   = var.organization
  workspace      = "platform"
  description    = "Production API service with strict controls"
  visibility     = "public"
  default_branch = "main"

  topics = ["api", "production", "backend"]

  properties = {
    environment = "production"
    cost-center = "engineering"
  }

  # Branch protection with strict requirements (flattened)
  protected_branches      = ["main", "release/*"]
  allow_bypass            = ["org-admin", "team:sre"]
  required_approvals      = 2
  required_checks         = ["ci", "security-scan", "integration-tests"]
  prevent_force_push      = true
  prevent_branch_deletion = true

  # Team and user permissions
  permissions = {
    "team:developers" = "push"
    "team:sre"        = "maintain"
    "user:vmvarela"   = "push"
  }

  # Deploy keys for CI/CD
  # deploy_keys = {
  #   "CI/CD Deploy Key" = {
  #     key       = var.ci_deploy_key
  #     read_only = false
  #   }
  # }

  # Repository-level secrets (global)
  repository_secrets = {
    DOCKER_USERNAME = var.docker_username
    DOCKER_PASSWORD = var.docker_password
  }

  # Repository-level variables
  repository_variables = {
    APP_NAME  = "production-api"
    LOG_LEVEL = "info"
    REGION    = "us-east-1"
  }

  # Environment-specific configurations
  environments = {
    production = {
      required_approvers = ["team:sre", "team:security-ops"]
      secrets = {
        API_KEY      = var.production_api_key
        DATABASE_URL = var.production_db_url
      }
      variables = {
        ENV          = "production"
        REPLICAS     = "5"
        ENABLE_CACHE = "true"
      }
    }

    staging = {
      required_approvers = ["team:sre"]
      secrets = {
        API_KEY      = var.staging_api_key
        DATABASE_URL = var.staging_db_url
      }
      variables = {
        ENV          = "staging"
        REPLICAS     = "2"
        ENABLE_CACHE = "false"
      }
    }
  }

  # Webhooks for CI/CD
  webhooks = {
    "ci-webhook" = {
      url    = var.ci_webhook_url
      events = ["push", "pull_request", "release"]
      secret = var.ci_webhook_secret
    }
  }

  # Required: IDs must be provided
  github_team_ids = local.github_team_ids
  github_user_ids = local.github_user_ids
  github_app_ids  = local.github_app_ids
}

# Example: Public library repository
module "open_source_library" {
  source = "../../"

  name         = "awesome-library"
  organization = var.organization
  workspace    = "open-source"
  description  = "Open source library for the community"
  visibility   = "public"

  topics = ["library", "open-source", "golang"]

  # Moderate protection for public library (flattened)
  protected_branches      = ["main"]
  required_approvals      = 1
  required_checks         = ["test", "lint", "build"]
  prevent_force_push      = true
  prevent_branch_deletion = false

  permissions = {
    "team:sre"        = "maintain"
    "team:developers" = "push"
  }

  # Only CI/CD secrets, no sensitive data in public repo
  repository_secrets = {
    NPM_TOKEN = var.npm_publish_token
  }

  # Required: IDs must be provided
  github_team_ids = local.github_team_ids
  github_user_ids = local.github_user_ids
  github_app_ids  = local.github_app_ids
}

# Example: Template repository
module "service_template" {
  source = "../../"

  name         = "service-template"
  organization = var.organization
  workspace    = "templates"
  description  = "Template for creating new microservices"
  visibility   = "public"
  is_template  = true

  topics = ["template", "microservice", "boilerplate"]

  properties = {
    owner       = "platform"
    cost-center = "engineering"
    environment = "development"
  }

  protected_branches = ["main"]
  required_approvals = 1
  required_checks    = ["test", "lint"]
  prevent_force_push = true

  # Required: IDs must be provided
  github_team_ids = local.github_team_ids
  github_user_ids = local.github_user_ids
  github_app_ids  = local.github_app_ids
}

# Example: Repository created from template
module "new_service_from_template" {
  source = "../../"

  name         = "payment-service"
  organization = var.organization
  workspace    = "platform"
  description  = "Payment processing service created from template"
  visibility   = "public"

  template = {
    repository           = "${var.organization}/service-template"
    include_all_branches = false
  }

  protected_branches = ["main", "develop"]
  required_approvals = 2
  required_checks    = ["ci", "security-scan"]
  prevent_force_push = true

  # Required: IDs must be provided
  github_team_ids = local.github_team_ids
  github_user_ids = local.github_user_ids
  github_app_ids  = local.github_app_ids

  depends_on = [module.service_template]
}
