# ============================================================================
# Main Terraform Configuration for Voting App GKE Deployment
# ============================================================================
# This configuration creates all necessary GCP resources for deploying
# the voting app to Google Kubernetes Engine (GKE)
# ============================================================================

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Uncomment to use remote state (recommended for teams)
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "voting-app/state"
  # }
}

# ============================================================================
# Provider Configuration
# ============================================================================

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Kubernetes provider - configured after GKE cluster is created
provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
}

# Get current client configuration
data "google_client_config" "default" {}

# ============================================================================
# Data Sources
# ============================================================================

# Get project information
data "google_project" "project" {
  project_id = var.project_id
}

# ============================================================================
# Enable Required APIs
# ============================================================================

resource "google_project_service" "required_apis" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
  ])

  project = var.project_id
  service = each.value

  disable_on_destroy = false
}

# ============================================================================
# GKE Cluster
# ============================================================================

module "gke" {
  source = "./modules/gke"

  project_id   = var.project_id
  cluster_name = var.cluster_name
  region       = var.region
  zones        = var.zones
  
  # Cluster configuration
  is_regional     = var.is_regional
  node_count      = var.node_count
  machine_type    = var.machine_type
  disk_size_gb    = var.disk_size_gb
  min_nodes       = var.min_nodes
  max_nodes       = var.max_nodes

  depends_on = [google_project_service.required_apis]
}

# ============================================================================
# Artifact Registry
# ============================================================================

module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_id      = var.project_id
  repository_name = var.artifact_registry_name
  location        = var.region
  description     = "Docker images for voting app"

  depends_on = [google_project_service.required_apis]
}

# ============================================================================
# Service Account for GitHub Actions
# ============================================================================

module "github_service_account" {
  source = "./modules/service-account"

  project_id         = var.project_id
  service_account_id = var.service_account_name
  display_name       = "GitHub Actions Deployment SA"
  description        = "Service account for automated deployments from GitHub Actions"
  
  # Grant required roles
  project_roles = [
    "roles/container.developer",
    "roles/artifactregistry.writer",
    "roles/storage.admin",
  ]

  depends_on = [google_project_service.required_apis]
}

# ============================================================================
# Workload Identity Federation
# ============================================================================

module "workload_identity" {
  source = "./modules/workload-identity"

  project_id     = var.project_id
  project_number = data.google_project.project.number
  
  pool_id          = var.workload_identity_pool_id
  pool_name        = "GitHub Actions Pool"
  provider_id      = var.workload_identity_provider_id
  provider_name    = "GitHub Provider"
  
  github_repo          = var.github_repository
  github_repo_owner    = var.github_repository_owner
  service_account_email = module.github_service_account.email

  depends_on = [
    google_project_service.required_apis,
    module.github_service_account
  ]
}

# ============================================================================
# Grant GKE access to Artifact Registry
# ============================================================================

resource "google_artifact_registry_repository_iam_member" "gke_reader" {
  project    = var.project_id
  location   = module.artifact_registry.location
  repository = module.artifact_registry.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    module.artifact_registry,
    module.gke
  ]
}

# ============================================================================
# Read LoadBalancer Services (if deployed)
# ============================================================================
# These data sources read the LoadBalancer services after they're deployed
# via GitHub Actions. Use: terraform refresh to update IPs after deployment

data "kubernetes_service" "vote_lb" {
  count = var.check_services ? 1 : 0
  
  metadata {
    name      = "vote-lb"
    namespace = "default"
  }

  depends_on = [module.gke]
}

data "kubernetes_service" "result_lb" {
  count = var.check_services ? 1 : 0
  
  metadata {
    name      = "result-lb"
    namespace = "default"
  }

  depends_on = [module.gke]
}
