terraform {
  required_version = ">= 1.6"

  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.6.0"
    }
  }
}

provider "github" {
  # GitHub token can be set via GITHUB_TOKEN environment variable
  # or you can set the owner here
  # owner = "your-github-username"
}

module "simple_repository" {
  source = "../.."

  # Basic repository settings
  name           = "my-simple-repo"
  description    = "A simple repository created with Terraform"
  visibility     = "public"
  default_branch = "main"

  # Repository features
  has_issues   = true
  has_wiki     = true
  has_projects = false

  # Topics for discoverability
  topics = ["terraform", "github", "infrastructure-as-code"]

  # Basic branch protection with ruleset
  rulesets = {
    "main-protection" = {
      target                             = "branch"
      include                            = ["main"]
      required_pr_approving_review_count = 1
      required_pr_code_owner_review      = true
    }
  }
}
