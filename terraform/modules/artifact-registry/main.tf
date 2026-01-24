# ============================================================================
# Artifact Registry Module
# ============================================================================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ============================================================================
# Artifact Registry Repository
# ============================================================================

resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.location
  repository_id = var.repository_name
  description   = var.description
  format        = "DOCKER"

  # Cleanup policy (optional)
  cleanup_policy_dry_run = false
  
  # You can add cleanup policies to automatically delete old images
  # dynamic "cleanup_policies" {
  #   for_each = var.cleanup_policies
  #   content {
  #     id     = cleanup_policies.value.id
  #     action = cleanup_policies.value.action
  #     condition {
  #       tag_state             = cleanup_policies.value.tag_state
  #       tag_prefixes          = cleanup_policies.value.tag_prefixes
  #       older_than            = cleanup_policies.value.older_than
  #       newer_than            = cleanup_policies.value.newer_than
  #       package_name_prefixes = cleanup_policies.value.package_name_prefixes
  #     }
  #   }
  # }

  labels = var.labels
}
