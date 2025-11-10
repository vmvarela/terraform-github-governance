provider "github" {
  owner = var.organization
  token = var.github_token
}

# Complete governance example - demonstrates advanced features
module "governance" {
  source            = "../.."
  organization      = var.organization
  workspace         = var.workspace
  repository_naming = var.repository_naming
  repositories      = var.repositories
  presets           = var.presets
}
