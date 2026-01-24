# ============================================================================
# Terraform Variables for Voting App Infrastructure
# ============================================================================

# ============================================================================
# Project Configuration
# ============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zones" {
  description = "GCP zones for node pools (zonal cluster)"
  type        = list(string)
  default     = ["us-central1-a"]
}

# ============================================================================
# GKE Cluster Configuration
# ============================================================================

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "dadismad-cluster-1"
}

variable "is_regional" {
  description = "Whether to create a regional cluster (true) or zonal cluster (false)"
  type        = bool
  default     = false
}

variable "node_count" {
  description = "Initial number of nodes per zone"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-2"
}

variable "disk_size_gb" {
  description = "Disk size for GKE nodes in GB"
  type        = number
  default     = 20
}

variable "min_nodes" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 4
}

# ============================================================================
# Artifact Registry Configuration
# ============================================================================

variable "artifact_registry_name" {
  description = "Name of the Artifact Registry repository"
  type        = string
  default     = "dadismad"
}

# ============================================================================
# GitHub Integration Configuration
# ============================================================================

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
  # Example: "dadismad-com/dadismad-voting-app"
}

variable "github_repository_owner" {
  description = "GitHub repository owner (organization or user)"
  type        = string
  # Example: "dadismad-com"
}

variable "service_account_name" {
  description = "Name of the service account for GitHub Actions"
  type        = string
  default     = "dadismad-github-actions"
}

variable "workload_identity_pool_id" {
  description = "ID of the Workload Identity Pool"
  type        = string
  default     = "github-actions-pool"
}

variable "workload_identity_provider_id" {
  description = "ID of the Workload Identity Provider"
  type        = string
  default     = "github-provider"
}

# ============================================================================
# Labels and Tags
# ============================================================================

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default = {
    application = "voting-app"
    managed-by  = "terraform"
    environment = "production"
  }
}

# ============================================================================
# Application Configuration
# ============================================================================

variable "check_services" {
  description = "Check for deployed Kubernetes services (LoadBalancers). Set to true after deploying via GitHub Actions."
  type        = bool
  default     = false
}
