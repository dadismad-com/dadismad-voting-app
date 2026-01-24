# ============================================================================
# GKE Module Variables
# ============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zones" {
  description = "GCP zones for node pools"
  type        = list(string)
}

variable "is_regional" {
  description = "Whether to create a regional cluster"
  type        = bool
}

variable "node_count" {
  description = "Initial number of nodes per zone"
  type        = number
}

variable "machine_type" {
  description = "Machine type for nodes"
  type        = string
}

variable "disk_size_gb" {
  description = "Disk size for nodes in GB"
  type        = number
}

variable "min_nodes" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
}

variable "max_nodes" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
