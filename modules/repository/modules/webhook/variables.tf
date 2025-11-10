variable "repository" {
  description = "The repository of the webhook."
  type        = string
}

variable "url" {
  description = "The URL of the webhook."
  type        = string
}

variable "events" {
  description = "A list of events which should trigger the webhook. See a list of [available events](https://docs.github.com/es/webhooks/webhook-events-and-payloads)."
  type        = set(string)
  default     = []
}

variable "content_type" {
  description = "The content type for the payload. Valid values are either `form` or `json`."
  type        = string
  validation {
    condition     = contains(["form", "json"], var.content_type)
    error_message = "Possible values for content_type are json or form."
  }
}

variable "insecure_ssl" {
  description = "Insecure SSL boolean toggle."
  type        = bool
  default     = false
}

variable "secret" {
  description = "The shared secret for the webhook"
  type        = string
  default     = null
}
