# ============================================================================
# Service Account Module Variables
# ============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "service_account_id" {
  description = "ID of the service account"
  type        = string
}

variable "display_name" {
  description = "Display name of the service account"
  type        = string
}

variable "description" {
  description = "Description of the service account"
  type        = string
  default     = ""
}

variable "project_roles" {
  description = "List of roles to grant to the service account"
  type        = list(string)
  default     = []
}
