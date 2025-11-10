# ========================================================================
# LEGACY OUTPUTS (Maintained for backwards compatibility)
# ========================================================================

output "file" {
  description = "Complete file object (use specific outputs for better terraform graph performance)"
  value       = github_repository_file.this
}

# ========================================================================
# FILE BASIC OUTPUTS
# ========================================================================

output "id" {
  description = "ID of the file resource"
  value       = github_repository_file.this.id
}

output "path" {
  description = "Path of the file in the repository"
  value       = github_repository_file.this.file
}

output "branch" {
  description = "Branch where the file was created"
  value       = github_repository_file.this.branch
}

output "commit_sha" {
  description = "SHA of the commit that created/updated the file"
  value       = github_repository_file.this.commit_sha
}

output "commit_message" {
  description = "Commit message used when creating/updating the file"
  value       = github_repository_file.this.commit_message
}

output "commit_author" {
  description = "Author of the commit"
  value       = github_repository_file.this.commit_author
}

output "commit_email" {
  description = "Email of the commit author"
  value       = github_repository_file.this.commit_email
}
