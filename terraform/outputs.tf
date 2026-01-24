# ============================================================================
# Terraform Outputs for Voting App Infrastructure
# ============================================================================

# ============================================================================
# Project Information
# ============================================================================

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "project_number" {
  description = "GCP Project Number"
  value       = data.google_project.project.number
}

output "region" {
  description = "GCP Region"
  value       = var.region
}

# ============================================================================
# GKE Cluster Information
# ============================================================================

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = module.gke.cluster_location
}

output "get_credentials_command" {
  description = "Command to get GKE credentials"
  value       = module.gke.get_credentials_command
}

# ============================================================================
# Artifact Registry Information
# ============================================================================

output "artifact_registry_name" {
  description = "Name of the Artifact Registry repository"
  value       = module.artifact_registry.name
}

output "artifact_registry_location" {
  description = "Location of the Artifact Registry repository"
  value       = module.artifact_registry.location
}

output "artifact_registry_url" {
  description = "Full URL of the Artifact Registry repository"
  value       = module.artifact_registry.repository_url
}

# ============================================================================
# Service Account Information
# ============================================================================

output "service_account_email" {
  description = "Email of the GitHub Actions service account"
  value       = module.github_service_account.email
}

output "service_account_name" {
  description = "Name of the GitHub Actions service account"
  value       = module.github_service_account.name
}

# ============================================================================
# Workload Identity Information
# ============================================================================

output "workload_identity_pool_name" {
  description = "Full name of the Workload Identity Pool"
  value       = module.workload_identity.pool_name
}

output "workload_identity_provider_name" {
  description = "Full name of the Workload Identity Provider"
  value       = module.workload_identity.provider_name
}

output "workload_identity_provider_full" {
  description = "Full provider path for GitHub Actions auth"
  value       = module.workload_identity.provider_full_path
}

# ============================================================================
# GitHub Actions Configuration
# ============================================================================

output "github_actions_config" {
  description = "Configuration values for GitHub Actions workflows"
  value = {
    project_id                  = var.project_id
    project_number              = data.google_project.project.number
    service_account            = module.github_service_account.email
    workload_identity_provider = module.workload_identity.provider_full_path
    artifact_registry_url      = module.artifact_registry.repository_url
    cluster_name               = module.gke.cluster_name
    cluster_location           = module.gke.cluster_location
  }
}

# ============================================================================
# kubectl Configuration Command
# ============================================================================

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = module.gke.get_credentials_command
}

# ============================================================================
# Summary
# ============================================================================

output "deployment_summary" {
  description = "Summary of deployed infrastructure"
  value = <<-EOT
  
  ╔═══════════════════════════════════════════════════════════╗
  ║           GKE Infrastructure Deployed Successfully!       ║
  ╚═══════════════════════════════════════════════════════════╝
  
  📦 Project: ${var.project_id} (${data.google_project.project.number})
  🌍 Region: ${var.region}
  
  🎯 GKE Cluster:
     Name: ${module.gke.cluster_name}
     Location: ${module.gke.cluster_location}
     Type: ${var.is_regional ? "Regional" : "Zonal"}
  
  📦 Artifact Registry:
     URL: ${module.artifact_registry.repository_url}
  
  🔐 Service Account:
     Email: ${module.github_service_account.email}
  
  🔑 Workload Identity:
     Provider: ${module.workload_identity.provider_full_path}
  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  📝 Next Steps:
  
  1. Configure kubectl:
     ${module.gke.get_credentials_command}
  
  2. Add GitHub Secret:
     Name: GKE_PROJECT
     Value: ${var.project_id}
  
  3. Update Kubernetes manifests:
     Replace PROJECT_ID with: ${var.project_id}
  
  4. Update GitHub Actions workflows:
     - workload_identity_provider: ${module.workload_identity.provider_full_path}
     - service_account: ${module.github_service_account.email}
  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  EOT
}
