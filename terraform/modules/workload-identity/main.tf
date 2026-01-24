# ============================================================================
# Workload Identity Federation Module
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
# Workload Identity Pool
# ============================================================================

resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = var.pool_name
  description               = "Workload Identity Pool for GitHub Actions"
  disabled                  = false
}

# ============================================================================
# Workload Identity Provider (GitHub OIDC)
# ============================================================================

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = var.provider_name
  description                        = "GitHub OIDC Provider for GitHub Actions"
  disabled                           = false

  # GitHub OIDC configuration
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }

  # Condition to restrict to specific GitHub organization
  attribute_condition = "assertion.repository_owner=='${var.github_repo_owner}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ============================================================================
# Service Account IAM Binding
# ============================================================================

# Allow GitHub Actions from the specified repository to impersonate the service account
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.service_account_email}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${var.pool_id}/attribute.repository/${var.github_repo}"
  
  depends_on = [
    google_iam_workload_identity_pool_provider.github_provider
  ]
}
