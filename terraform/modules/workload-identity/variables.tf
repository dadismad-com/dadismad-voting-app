# ============================================================================
# Workload Identity Module Variables
# ============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_number" {
  description = "GCP Project Number"
  type        = string
}

variable "pool_id" {
  description = "ID of the Workload Identity Pool"
  type        = string
}

variable "pool_name" {
  description = "Display name of the Workload Identity Pool"
  type        = string
}

variable "provider_id" {
  description = "ID of the Workload Identity Provider"
  type        = string
}

variable "provider_name" {
  description = "Display name of the Workload Identity Provider"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo"
  type        = string
}

variable "github_repo_owner" {
  description = "GitHub repository owner (organization or user)"
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account to bind"
  type        = string
}
