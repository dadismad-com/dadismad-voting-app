# ============================================================================
# Artifact Registry Module Outputs
# ============================================================================

output "name" {
  description = "Name of the Artifact Registry repository"
  value       = google_artifact_registry_repository.repo.repository_id
}

output "id" {
  description = "ID of the Artifact Registry repository"
  value       = google_artifact_registry_repository.repo.id
}

output "location" {
  description = "Location of the Artifact Registry repository"
  value       = google_artifact_registry_repository.repo.location
}

output "repository_url" {
  description = "Full URL of the Artifact Registry repository"
  value       = "${google_artifact_registry_repository.repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}
