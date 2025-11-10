# This example uses hardcoded values in main.tf for demonstration purposes.
# In a real scenario, you would define variables here and use a terraform.tfvars file
# or pass variables via command line.

# Example of how you might structure variables:
#
# variable "repository_name" {
#   description = "The name of the repository"
#   type        = string
# }
#
# variable "github_users" {
#   description = "Map of GitHub users and their permissions"
#   type        = map(string)
#   default     = {}
# }
#
# variable "github_teams" {
#   description = "Map of GitHub teams and their permissions"
#   type        = map(string)
#   default     = {}
# }
