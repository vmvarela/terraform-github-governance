variable "github_token" {
  description = "GitHub token"
  type        = string
  sensitive   = true
  default     = null
}

variable "name" {
  description = "The shorthand name of the project/organization."
  type        = string
  default     = null
}

variable "description" {
  description = "A brief description of the project/organization."
  type        = string
  default     = null
}

variable "billing_email" {
  description = "The billing email for the organization."
  type        = string
  default     = null
}
