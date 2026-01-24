# 🏗️ Terraform Infrastructure as Code for Voting App

This directory contains Terraform configurations to deploy the complete GKE infrastructure for the voting application.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Project Structure](#project-structure)
5. [Usage](#usage)
6. [Environments](#environments)
7. [Modules](#modules)
8. [Customization](#customization)
9. [Maintenance](#maintenance)
10. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

### What This Creates

This Terraform configuration deploys:

- ✅ **GKE Cluster** - Kubernetes cluster (zonal or regional)
- ✅ **Artifact Registry** - Docker image repository
- ✅ **Service Account** - For GitHub Actions deployments
- ✅ **Workload Identity** - Secure authentication (no keys!)
- ✅ **IAM Bindings** - Proper permissions for all resources

### Why Terraform?

**vs Bash Scripts:**
- ✅ Declarative (describe what you want, not how)
- ✅ State management (tracks what exists)
- ✅ Idempotent (safe to re-run)
- ✅ Version controlled infrastructure
- ✅ Easier to maintain and update
- ✅ Better for teams
- ✅ Preview changes before applying

---

## 📋 Prerequisites

### Required Tools

```bash
# Terraform (>= 1.5)
brew install terraform

# Google Cloud SDK
brew install --cask google-cloud-sdk

# kubectl
brew install kubectl
```

### Required Access

- ✅ GCP Project with billing enabled
- ✅ GCP Project Owner or Editor role
- ✅ GitHub repository access

### Authentication

```bash
# Login to Google Cloud
gcloud auth login
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID
```

---

## 🚀 Quick Start

### 1. Initialize Configuration

```bash
# Navigate to terraform directory
cd terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Required values in `terraform.tfvars`:**
```hcl
project_id              = "your-gcp-project-id"
github_repository       = "owner/repo"
github_repository_owner = "owner"
```

### 2. Initialize Terraform

```bash
# Download providers and initialize backend
terraform init
```

Expected output:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### 3. Plan Infrastructure

```bash
# Preview what will be created
terraform plan
```

This shows you exactly what Terraform will create/modify/destroy.

### 4. Apply Configuration

```bash
# Create the infrastructure
terraform apply
```

Type `yes` when prompted. This takes **10-15 minutes** (cluster creation is slow).

### 5. Get Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output github_actions_config
```

---

## 📁 Project Structure

```
terraform/
├── main.tf                    # Main configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example variables
├── terraform.tfvars           # Your variables (gitignored)
│
├── modules/                   # Reusable modules
│   ├── gke/                  # GKE cluster module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── artifact-registry/    # Artifact Registry module
│   ├── service-account/      # Service Account module
│   └── workload-identity/    # Workload Identity module
│
└── environments/              # Environment-specific configs
    ├── dev/                  # Development environment
    │   └── terraform.tfvars
    └── prod/                 # Production environment
        └── terraform.tfvars
```

---

## 💻 Usage

### Common Commands

```bash
# Initialize (first time or after adding modules)
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy

# Show current state
terraform show

# List resources
terraform state list

# View specific resource
terraform state show module.gke.google_container_cluster.primary
```

### Working with Outputs

```bash
# Get all outputs
terraform output

# Get specific output (JSON)
terraform output -json github_actions_config

# Get raw value (for scripts)
terraform output -raw service_account_email
```

### Updating Infrastructure

```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Preview changes
terraform plan

# Apply changes
terraform apply
```

---

## 🌍 Environments

### Development Environment

**Location:** `environments/dev/`

**Characteristics:**
- Zonal cluster (cheaper)
- Smaller nodes (e2-standard-2)
- Fewer resources
- Cost: ~$100/month

**Usage:**
```bash
# Use dev config
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Production Environment

**Location:** `environments/prod/`

**Characteristics:**
- Regional cluster (HA)
- Larger nodes (n1-standard-2)
- More autoscaling capacity
- Cost: ~$300/month

**Usage:**
```bash
# Use prod config
terraform apply -var-file=environments/prod/terraform.tfvars
```

### Creating Additional Environments

```bash
# Create staging environment
mkdir -p environments/staging
cp environments/dev/terraform.tfvars environments/staging/

# Edit for staging
nano environments/staging/terraform.tfvars

# Apply
terraform apply -var-file=environments/staging/terraform.tfvars
```

---

## 🧩 Modules

### GKE Module

**Location:** `modules/gke/`

**Creates:**
- GKE Cluster
- Node Pool with autoscaling
- Workload Identity enabled
- Shielded nodes

**Key Variables:**
- `cluster_name` - Name of the cluster
- `is_regional` - Regional (true) or Zonal (false)
- `machine_type` - Node machine type
- `min_nodes` / `max_nodes` - Autoscaling limits

### Artifact Registry Module

**Location:** `modules/artifact-registry/`

**Creates:**
- Docker repository
- Configurable location
- Optional cleanup policies

**Key Variables:**
- `repository_name` - Registry name
- `location` - GCP region

### Service Account Module

**Location:** `modules/service-account/`

**Creates:**
- Service Account
- IAM role bindings

**Key Variables:**
- `service_account_id` - Account ID
- `project_roles` - List of roles to grant

### Workload Identity Module

**Location:** `modules/workload-identity/`

**Creates:**
- Workload Identity Pool
- OIDC Provider for GitHub
- IAM binding for service account

**Key Variables:**
- `github_repo` - Repository path
- `github_repo_owner` - Repository owner

---

## ⚙️ Customization

### Change Cluster Size

Edit `terraform.tfvars`:
```hcl
# Smaller cluster
node_count   = 1
machine_type = "e2-medium"
max_nodes    = 3

# Larger cluster
node_count   = 3
machine_type = "n1-standard-4"
max_nodes    = 10
```

### Add Backup Node Pool

Edit `modules/gke/main.tf`:
```hcl
resource "google_container_node_pool" "backup_pool" {
  name     = "${var.cluster_name}-backup-pool"
  location = google_container_cluster.primary.location
  cluster  = google_container_cluster.primary.name
  
  node_config {
    preemptible  = true  # Cheaper!
    machine_type = "e2-medium"
  }
}
```

### Enable Binary Authorization

Edit `modules/gke/main.tf`:
```hcl
resource "google_container_cluster" "primary" {
  # ... existing config ...
  
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }
}
```

### Add Multiple GitHub Repositories

Edit `modules/workload-identity/main.tf`:
```hcl
resource "google_service_account_iam_member" "workload_identity_binding" {
  for_each = toset(var.github_repos)  # Multiple repos
  
  service_account_id = "..."
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://.../${each.value}"
}
```

---

## 🔧 Maintenance

### Upgrading GKE Version

```bash
# Check available versions
gcloud container get-server-config --region us-central1

# Update terraform.tfvars (if pinned)
# Or let GKE auto-upgrade via release channel

# Apply
terraform apply
```

### Scaling Cluster

```bash
# Edit terraform.tfvars
min_nodes = 3
max_nodes = 10

# Apply
terraform apply
```

### Rotating Service Account

```bash
# Create new service account
# Update github_actions_config
# Update GitHub secrets
# Delete old service account

terraform apply
```

### State Management

```bash
# Pull state locally
terraform state pull > state.json

# Push state
terraform state push state.json

# Move resource
terraform state mv module.old.resource module.new.resource

# Remove resource from state (doesn't delete resource)
terraform state rm module.resource.name
```

### Remote State (Recommended)

Edit `main.tf`:
```hcl
terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "voting-app/state"
  }
}
```

Then:
```bash
# Initialize backend
terraform init -migrate-state
```

---

## 🐛 Troubleshooting

### Error: APIs Not Enabled

**Problem:**
```
Error: Error creating Cluster: googleapi: Error 403: ...
```

**Solution:**
```bash
# Enable APIs manually
gcloud services enable container.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com

# Wait 2-3 minutes, then retry
terraform apply
```

### Error: Quota Exceeded

**Problem:**
```
Error: Quota 'CPUS' exceeded. Limit: 24.0
```

**Solution:**
1. Request quota increase in GCP Console
2. Or reduce cluster size:
```hcl
node_count   = 1
machine_type = "e2-small"
```

### Error: Cluster Already Exists

**Problem:**
```
Error: Error creating Cluster: googleapi: Error 409: Already exists
```

**Solution:**
```bash
# Import existing cluster
terraform import module.gke.google_container_cluster.primary \
  projects/PROJECT_ID/locations/LOCATION/clusters/CLUSTER_NAME

# Then apply
terraform apply
```

### Error: Permission Denied

**Problem:**
```
Error: Error creating ServiceAccount: googleapi: Error 403: Permission denied
```

**Solution:**
```bash
# Check your roles
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:YOUR_EMAIL"

# Need: roles/editor or roles/owner
```

### State Lock Issues

**Problem:**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Force unlock (use carefully!)
terraform force-unlock LOCK_ID

# Or wait for lock to expire (usually 20 minutes)
```

### Drift Detection

```bash
# Check if infrastructure matches state
terraform plan -refresh-only

# Update state to match reality
terraform apply -refresh-only
```

---

## 📊 Cost Estimation

### Development (Zonal)
- GKE Cluster: ~$73/month
- Nodes (2x e2-standard-2): ~$30/month
- Artifact Registry: ~$5/month
- **Total: ~$108/month**

### Production (Regional)
- GKE Cluster: ~$219/month (3 zones)
- Nodes (3x n1-standard-2): ~$150/month
- Artifact Registry: ~$10/month
- **Total: ~$379/month**

### Cost Optimization Tips

1. **Use Spot/Preemptible nodes:**
```hcl
node_config {
  preemptible = true  # 60-91% cheaper!
}
```

2. **Enable autoscaling:**
```hcl
autoscaling {
  min_node_count = 1
  max_node_count = 5
}
```

3. **Use smaller machines:**
```hcl
machine_type = "e2-small"  # Cheapest
```

4. **Delete dev cluster when not in use:**
```bash
terraform destroy -var-file=environments/dev/terraform.tfvars
```

---

## 🔐 Security Best Practices

### 1. Never Commit Secrets

```bash
# In .gitignore
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform/
```

### 2. Use Remote State

Store state in GCS bucket with encryption:
```hcl
backend "gcs" {
  bucket                      = "terraform-state"
  encryption_key             = "..."
  impersonate_service_account = "terraform@project.iam.gserviceaccount.com"
}
```

### 3. Restrict Workload Identity

Only allow specific repos:
```hcl
attribute_condition = "assertion.repository=='owner/specific-repo'"
```

### 4. Enable Binary Authorization

Require signed images:
```hcl
binary_authorization {
  evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
}
```

### 5. Use Service Account for Terraform

```bash
# Create SA
gcloud iam service-accounts create terraform

# Grant roles
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:terraform@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# Use SA
export GOOGLE_APPLICATION_CREDENTIALS="path/to/key.json"
```

---

## 📚 Additional Resources

- [Terraform GCP Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

## 🆚 Terraform vs Bash Scripts

| Aspect | Terraform | Bash Scripts |
|--------|-----------|--------------|
| **Idempotency** | ✅ Built-in | ⚠️ Manual checks |
| **State Management** | ✅ Automatic | ❌ Manual |
| **Preview Changes** | ✅ `terraform plan` | ❌ No preview |
| **Rollback** | ✅ Easy | ⚠️ Manual |
| **Team Collaboration** | ✅ Remote state | ⚠️ Difficult |
| **Documentation** | ✅ Self-documenting | ⚠️ Must maintain |
| **Drift Detection** | ✅ Built-in | ❌ Manual |
| **Learning Curve** | ⚠️ Medium | ✅ Easy |
| **Execution Speed** | ✅ Parallel | ⚠️ Sequential |
| **Cost** | ✅ Free | ✅ Free |

---

## ✅ Migration from Bash Scripts

If you're migrating from `setup-gke.sh`:

```bash
# 1. Run Terraform
terraform apply

# 2. Terraform creates same resources as script

# 3. No need to run setup-gke.sh anymore

# 4. To destroy:
terraform destroy
# (replaces cleanup-gke.sh)
```

**Benefits:**
- ✅ Safer (preview before apply)
- ✅ Faster (parallel execution)
- ✅ Easier to update
- ✅ Version controlled
- ✅ Better for teams

---

**Questions?** See main project documentation or create an issue.

**Ready to deploy?** Run `terraform apply`! 🚀
