# 🏗️ Terraform Quick Start Guide

**Infrastructure as Code for Voting App GKE Deployment**

---

## ⚡ 5-Minute Setup

### 1. Prerequisites

```bash
# Install Terraform
brew install terraform

# Already have gcloud & kubectl from main setup
```

### 2. Configure

```bash
cd terraform

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Minimum required:**
```hcl
project_id              = "your-gcp-project-id"
github_repository       = "dadismad-com/dadismad-voting-app"
github_repository_owner = "dadismad-com"
```

### 3. Deploy

```bash
# Initialize
terraform init

# Preview
terraform plan

# Deploy (takes ~10-15 minutes)
terraform apply
```

Type `yes` when prompted.

### 4. Get Configuration

```bash
# View all outputs
terraform output

# Get specific values for GitHub Actions
terraform output github_actions_config
```

---

## 🎯 What Gets Created

Same as `setup-gke.sh` but declarative:

- ✅ GKE Cluster
- ✅ Artifact Registry
- ✅ Service Account
- ✅ Workload Identity Federation
- ✅ IAM Bindings

---

## 🆚 Terraform vs Bash Scripts

| Feature | Terraform | Bash Scripts |
|---------|-----------|--------------|
| **Setup** | `terraform apply` | `./setup-gke.sh` |
| **Teardown** | `terraform destroy` | `./cleanup-gke.sh` |
| **Preview** | ✅ `terraform plan` | ❌ No preview |
| **State** | ✅ Automatic | ⚠️ Manual |
| **Updates** | ✅ Easy | ⚠️ Manual changes |
| **Rollback** | ✅ Built-in | ❌ Manual |
| **Team Use** | ✅ Remote state | ⚠️ Difficult |

---

## 🔄 Common Operations

### Update Infrastructure

```bash
# Edit terraform.tfvars
nano terraform.tfvars

# Preview changes
terraform plan

# Apply changes
terraform apply
```

### Scale Cluster

```bash
# Edit terraform.tfvars
max_nodes = 10

# Apply
terraform apply
```

### Destroy Everything

```bash
terraform destroy
```

Type `yes` when prompted. Faster than `cleanup-gke.sh`!

---

## 📊 Environments

### Development (Cheap)

```bash
# Use dev config
terraform apply -var-file=environments/dev/terraform.tfvars
```

**Cost:** ~$100/month (zonal cluster)

### Production (HA)

```bash
# Use prod config
terraform apply -var-file=environments/prod/terraform.tfvars
```

**Cost:** ~$300/month (regional cluster)

---

## 🔧 Customization

### Change Machine Type

Edit `terraform.tfvars`:
```hcl
machine_type = "n1-standard-4"  # Bigger nodes
# or
machine_type = "e2-small"       # Smaller nodes
```

### Switch to Regional

Edit `terraform.tfvars`:
```hcl
is_regional = true
node_count  = 1
min_nodes   = 3
max_nodes   = 10
```

---

## 🐛 Troubleshooting

### APIs Not Enabled

```bash
# Enable manually
gcloud services enable container.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com

# Wait 2 minutes, retry
terraform apply
```

### Cluster Already Exists

```bash
# Import existing
terraform import module.gke.google_container_cluster.primary \
  projects/PROJECT_ID/locations/LOCATION/clusters/CLUSTER_NAME

terraform apply
```

### Permission Denied

```bash
# Check your roles
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:YOUR_EMAIL"

# Need: roles/editor or roles/owner
```

---

## 📚 Full Documentation

See [`terraform/README.md`](terraform/README.md) for:
- Complete module documentation
- Advanced customization
- Security best practices
- Cost optimization
- Team workflows

---

## ✅ Why Use Terraform?

### Advantages

1. **Safer** - Preview changes before applying
2. **Faster** - Parallel resource creation
3. **Repeatable** - Same result every time
4. **Version Controlled** - Infrastructure as code
5. **Team Friendly** - Remote state, locking
6. **Easier Updates** - Change config, apply
7. **Self-Documenting** - Code is documentation

### When to Use Bash Scripts

- ✅ Quick one-time setup
- ✅ Don't want to learn Terraform
- ✅ Solo developer
- ✅ Simple requirements

### When to Use Terraform

- ✅ Team environment
- ✅ Multiple environments (dev/staging/prod)
- ✅ Frequent updates
- ✅ Want infrastructure history
- ✅ Need compliance/auditing
- ✅ **Recommended for production!**

---

## 🔄 Migration Path

### From Bash Scripts to Terraform

```bash
# 1. Run Terraform
cd terraform
terraform apply

# 2. Resources now managed by Terraform

# 3. Don't run bash scripts anymore
# (they'll conflict with Terraform)

# 4. Use Terraform for all operations
terraform plan   # Preview
terraform apply  # Update
terraform destroy  # Cleanup
```

### From Terraform to Bash Scripts

```bash
# 1. Destroy Terraform resources
terraform destroy

# 2. Run bash script
cd ..
./setup-gke.sh
```

**Note:** Can't run both simultaneously - they'll conflict!

---

## 🚀 Ready to Start?

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

That's it! Infrastructure as code is that easy. 🎉

---

**Questions?** See `terraform/README.md` or main project docs.
