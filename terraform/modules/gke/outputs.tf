# ============================================================================
# GKE Module Outputs
# ============================================================================

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_id" {
  description = "ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "node_pool_name" {
  description = "Name of the primary node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "get_credentials_command" {
  description = "Command to get GKE credentials"
  value       = var.is_regional ? "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region}" : "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zones[0]}"
}
