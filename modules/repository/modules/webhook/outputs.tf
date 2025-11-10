# ========================================================================
# LEGACY OUTPUTS (Maintained for backwards compatibility)
# ========================================================================

output "webhook" {
  description = "Complete webhook object (use specific outputs for better terraform graph performance)"
  value       = github_repository_webhook.this
}

# ========================================================================
# WEBHOOK BASIC OUTPUTS
# ========================================================================

output "id" {
  description = "Numeric ID of the webhook"
  value       = github_repository_webhook.this.id
}

output "url" {
  description = "URL of the webhook endpoint"
  value       = github_repository_webhook.this.url
}

output "active" {
  description = "Whether the webhook is active"
  value       = github_repository_webhook.this.active
}

output "events" {
  description = "List of events that trigger the webhook"
  value       = github_repository_webhook.this.events
}

output "content_type" {
  description = "Content type of the webhook payload"
  value       = try(github_repository_webhook.this.configuration[0].content_type, null)
}

output "insecure_ssl" {
  description = "Whether to verify SSL certificates"
  value       = try(github_repository_webhook.this.configuration[0].insecure_ssl, null)
}
