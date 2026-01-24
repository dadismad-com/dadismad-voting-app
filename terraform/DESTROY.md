# Destroying the GKE Cluster

This guide explains how to safely destroy your GKE infrastructure when you no longer need it.

## ⚠️ Warning

**Destroying the cluster will:**
- Delete all deployed applications
- Remove all data in the cluster
- Delete the GKE cluster itself
- This action is **irreversible**

**What will NOT be deleted:**
- Artifact Registry repository (images are preserved)
- Service Account
- Workload Identity Pool/Provider
- IAM bindings

## 🛡️ Deletion Protection

By default, GKE clusters have **deletion protection enabled** to prevent accidental deletion. You must explicitly disable it before destroying.

### Current Protection Status

Check if deletion protection is enabled:

```bash
# View current state
terraform show | grep deletion_protection

# Or check directly
gcloud container clusters describe dadismad-cluster-1 \
  --zone us-central1-a \
  --format="value(deletionProtection)"
```

## 🗑️ How to Destroy

### Method 1: Terraform with Variable Override (Recommended)

```bash
cd terraform

# Destroy with deletion protection disabled
terraform destroy -var='deletion_protection=false'
```

This will:
1. Temporarily disable deletion protection
2. Destroy all resources
3. Confirm before proceeding

### Method 2: Update terraform.tfvars

```bash
cd terraform

# Edit your terraform.tfvars
echo 'deletion_protection = false' >> terraform.tfvars

# Apply the change (disables protection)
terraform apply

# Now destroy
terraform destroy
```

### Method 3: Manual GCloud Command (Last Resort)

If Terraform isn't working:

```bash
# Disable deletion protection
gcloud container clusters update dadismad-cluster-1 \
  --zone us-central1-a \
  --no-deletion-protection

# Delete the cluster
gcloud container clusters delete dadismad-cluster-1 \
  --zone us-central1-a \
  --quiet
```

## 📋 Step-by-Step Destruction Process

### 1. Backup Important Data (if needed)

```bash
# Export Kubernetes resources
kubectl get all --all-namespaces -o yaml > k8s-backup.yaml

# Export application data (if any)
# ... your backup commands here ...
```

### 2. Verify What Will Be Destroyed

```bash
cd terraform

# See destruction plan
terraform plan -destroy -var='deletion_protection=false'
```

Expected output:
```
Plan: 0 to add, 0 to change, X to destroy.
```

### 3. Destroy the Infrastructure

```bash
# Run destroy
terraform destroy -var='deletion_protection=false'

# Review the plan
# Type 'yes' when prompted
```

### 4. Verify Deletion

```bash
# Check cluster is gone
gcloud container clusters list --project dadismad-sysdig

# Check remaining resources
terraform state list
```

## 🧹 Clean Up Remaining Resources

After destroying, you may want to clean up other resources:

### Option A: Keep Everything for Future Use

If you plan to redeploy later, keep:
- ✅ Artifact Registry (images)
- ✅ Service Account
- ✅ Workload Identity setup

### Option B: Complete Cleanup

```bash
cd terraform

# Destroy ALL remaining resources
terraform destroy

# This will remove:
# - Artifact Registry
# - Service Account
# - Workload Identity Pool/Provider
# - IAM bindings
```

### Option C: Manual Selective Cleanup

```bash
# Delete Artifact Registry only
gcloud artifacts repositories delete dadismad \
  --location us-central1 \
  --project dadismad-sysdig

# Delete Service Account
gcloud iam service-accounts delete \
  dadismad-github-actions@dadismad-sysdig.iam.gserviceaccount.com \
  --project dadismad-sysdig

# Delete Workload Identity Pool
gcloud iam workload-identity-pools delete github-actions-pool \
  --location global \
  --project dadismad-sysdig
```

## 💰 Cost Savings

After destroying the cluster:

**Monthly Savings:**
- GKE Cluster: ~$0.10/hour × 730 hours = **~$73/month**
- Node VMs (2 × e2-standard-2): ~$0.067/hour × 2 × 730 = **~$98/month**
- LoadBalancers (2): ~$18/month × 2 = **~$36/month**
- **Total Savings: ~$207/month**

**Remaining Costs:**
- Artifact Registry storage: ~$0.10/GB/month (minimal if few images)

## 🔄 Redeployment

To recreate the infrastructure later:

```bash
cd terraform

# Recreate with deletion protection enabled (default)
terraform apply

# Or without protection for testing
terraform apply -var='deletion_protection=false'
```

## 🐛 Troubleshooting

### Error: "deletion_protection is set to true"

**Solution:**
```bash
terraform destroy -var='deletion_protection=false'
```

### Error: "Error destroying Node Pool"

**Solution:** Node pools are dependent on the cluster. Ensure cluster deletion protection is disabled first.

```bash
# Check cluster protection
gcloud container clusters describe dadismad-cluster-1 \
  --zone us-central1-a \
  --format="value(deletionProtection)"

# If true, disable it
terraform apply -var='deletion_protection=false'

# Then destroy
terraform destroy -var='deletion_protection=false'
```

### Error: "Resource still in use"

**Solution:** Some resources may have dependencies. Try:

```bash
# Remove specific resources first
terraform destroy -target=module.gke -var='deletion_protection=false'

# Then destroy the rest
terraform destroy
```

### Cluster Stuck in "Deleting" State

**Solution:** This can take 10-15 minutes. Wait for completion.

```bash
# Check status
gcloud container clusters list --project dadismad-sysdig

# Watch deletion progress
watch -n 10 'gcloud container clusters list --project dadismad-sysdig'
```

## 📊 Destruction Checklist

Before destroying:

- [ ] Backup any important data
- [ ] Export Kubernetes manifests if needed
- [ ] Notify team members
- [ ] Verify you're destroying the correct cluster
- [ ] Check for any production workloads
- [ ] Review terraform plan before confirming

After destroying:

- [ ] Verify cluster is deleted
- [ ] Check for orphaned resources
- [ ] Update documentation
- [ ] Remove GitHub secrets if not redeploying
- [ ] Cancel any alerts/monitoring

## 🔐 Security Note

**Production Clusters:**
- Keep `deletion_protection = true` (default)
- Require explicit override to destroy
- Use separate Terraform workspaces for prod vs dev

**Development/Testing Clusters:**
- Can set `deletion_protection = false` in terraform.tfvars
- Easier to tear down and recreate
- Lower risk of data loss

## 📚 Related Documentation

- [Terraform Destroy](https://www.terraform.io/cli/commands/destroy)
- [GKE Deletion Protection](https://cloud.google.com/kubernetes-engine/docs/how-to/deletion-protection)
- [Terraform State](https://www.terraform.io/language/state)

---

**Need to destroy the cluster?**

```bash
cd terraform
terraform destroy -var='deletion_protection=false'
```

**Changed your mind?**

Press `Ctrl+C` during the confirmation prompt to cancel.
