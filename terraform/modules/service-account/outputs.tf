# ============================================================================
# Service Account Module Outputs
# ============================================================================

output "email" {
  description = "Email of the service account"
  value       = google_service_account.sa.email
}

output "name" {
  description = "Name of the service account"
  value       = google_service_account.sa.name
}

output "id" {
  description = "ID of the service account"
  value       = google_service_account.sa.id
}

output "unique_id" {
  description = "Unique ID of the service account"
  value       = google_service_account.sa.unique_id
}
