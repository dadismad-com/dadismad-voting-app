# Connect GitHub to GKE - Step-by-Step Setup

**Time Required:** 30-45 minutes  
**Prerequisites:** Google Cloud account with billing enabled

This guide will walk you through connecting your GitHub repository to GKE for automated deployments.

---

## 🎯 What You'll Set Up

1. ✅ Google Cloud Project
2. ✅ GKE Cluster
3. ✅ Artifact Registry
4. ✅ Service Account with Permissions
5. ✅ Workload Identity Federation (GitHub ↔ GCP)
6. ✅ GitHub Secrets
7. ✅ First Deployment

---

## 📋 Part 1: Google Cloud Setup (20 minutes)

### Step 1: Create/Select GCP Project

```bash
# Login to Google Cloud
gcloud auth login

# Set your project ID (choose a unique name)
export PROJECT_ID="dadismad-voting-app-$(date +%s)"
echo "Your project ID: $PROJECT_ID"

# Create the project
gcloud projects create $PROJECT_ID --name="Voting App"

# Set as active project
gcloud config set project $PROJECT_ID

# Link billing account (REQUIRED - replace with your billing account ID)
# Find your billing account: https://console.cloud.google.com/billing
gcloud beta billing projects link $PROJECT_ID \
  --billing-account=YOUR-BILLING-ACCOUNT-ID
```

**Find your billing account:**
1. Go to: https://console.cloud.google.com/billing
2. Copy the Billing Account ID
3. Replace `YOUR-BILLING-ACCOUNT-ID` above

### Step 2: Enable Required APIs

```bash
# Enable all necessary APIs (takes ~2 minutes)
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  compute.googleapis.com

echo "✅ APIs enabled"
```

### Step 3: Create Artifact Registry

```bash
# Create Docker repository for your images
gcloud artifacts repositories create dadismad \
  --repository-format=docker \
  --location=us-central1 \
  --description="Voting app Docker images"

echo "✅ Artifact Registry created"
echo "Registry: us-central1-docker.pkg.dev/$PROJECT_ID/dadismad"
```

### Step 4: Create GKE Cluster

**Option A: Development Cluster (Cheaper, ~$100/month)**

```bash
gcloud container clusters create dadismad-cluster-1 \
  --zone us-central1-a \
  --num-nodes 2 \
  --machine-type e2-standard-2 \
  --disk-size 20GB \
  --enable-autoscaling \
  --min-nodes 2 \
  --max-nodes 4 \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-ip-alias

echo "✅ Development GKE cluster created"
```

**Option B: Production Cluster (More expensive, ~$300/month)**

```bash
gcloud container clusters create dadismad-cluster-1 \
  --region us-central1 \
  --num-nodes 1 \
  --machine-type n1-standard-2 \
  --disk-size 50GB \
  --enable-autoscaling \
  --min-nodes 3 \
  --max-nodes 10 \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-ip-alias

echo "✅ Production GKE cluster created"
```

**Get cluster credentials:**

```bash
# For zonal cluster (Option A)
gcloud container clusters get-credentials dadismad-cluster-1 \
  --zone us-central1-a

# OR for regional cluster (Option B)
gcloud container clusters get-credentials dadismad-cluster-1 \
  --region us-central1

# Verify connection
kubectl get nodes

echo "✅ Connected to GKE cluster"
```

---

## 🔐 Part 2: Service Account Setup (10 minutes)

### Step 5: Create Service Account for GitHub Actions

```bash
# Create service account
gcloud iam service-accounts create dadismad-github-actions \
  --display-name="GitHub Actions Deployment SA" \
  --description="Service account for automated deployments from GitHub Actions"

# Get service account email
export SA_EMAIL="dadismad-github-actions@${PROJECT_ID}.iam.gserviceaccount.com"
echo "Service Account: $SA_EMAIL"

# Grant necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"

echo "✅ Service account created and permissions granted"
```

### Step 6: Configure Workload Identity Federation

**This allows GitHub Actions to authenticate without storing keys!**

```bash
# Get your project number
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
echo "Project Number: $PROJECT_NUMBER"

# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-actions-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create provider for GitHub
gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Allow GitHub to impersonate service account (REPLACE YOUR-GITHUB-ORG)
export GITHUB_REPO="dadismad-com/dadismad-voting-app"
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/${GITHUB_REPO}"

echo "✅ Workload Identity Federation configured"
```

**Save these values (you'll need them for GitHub):**

```bash
echo ""
echo "==================== SAVE THESE VALUES ===================="
echo "PROJECT_ID: $PROJECT_ID"
echo "PROJECT_NUMBER: $PROJECT_NUMBER"
echo "SERVICE_ACCOUNT: $SA_EMAIL"
echo "WORKLOAD_IDENTITY_PROVIDER: projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider"
echo "=========================================================="
echo ""
```

---

## 🔧 Part 3: Update Your Repository (5 minutes)

### Step 7: Update Kubernetes Deployment Files

You need to replace `PROJECT_ID` placeholders in your Kubernetes files.

```bash
# Navigate to your repo
cd /Users/migueldelossantos/Downloads/dadismad-voting-app

# Replace PROJECT_ID in all K8s deployment files
sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" k8s-specifications/vote-deployment.yaml
sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" k8s-specifications/result-deployment.yaml
sed -i '' "s/PROJECT_ID/$PROJECT_ID/g" k8s-specifications/worker-deployment.yaml

# Verify changes
grep "image:" k8s-specifications/vote-deployment.yaml

echo "✅ Kubernetes files updated with your project ID"
```

### Step 8: Update GitHub Action Workflows

**Update the cluster zone/region in workflows:**

```bash
# Check your cluster zone/region
gcloud container clusters list --format="table(name,location)"

# If using ZONAL cluster (us-central1-a):
# - Keep GKE_ZONE: us-central1-a in workflows
# - Already set correctly ✅

# If using REGIONAL cluster (us-central1):
# - Need to update GKE_ZONE to us-central1 in workflows
```

**Update all 5 workflow files if using regional cluster:**

Edit these files and change:
```yaml
GKE_ZONE: us-central1  # Change from us-central1-a if regional
```

Files to update:
- `.github/workflows/call-gke-build-vote.yaml`
- `.github/workflows/call-gke-build-result.yaml`
- `.github/workflows/call-gke-build-worker.yaml`
- `.github/workflows/call-gke-build-db.yaml`
- `.github/workflows/call-gke-build-redis.yaml`

### Step 9: Update Workload Identity in Workflows

**Update all 5 workflow files with your actual values:**

```bash
# Get your values
echo "Replace these in ALL workflow files:"
echo "workload_identity_provider: 'projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider'"
echo "service_account: '${SA_EMAIL}'"
```

**Files to update:**
- `.github/workflows/call-gke-build-vote.yaml` (line 90-91)
- `.github/workflows/call-gke-build-result.yaml` (line 86-87)
- `.github/workflows/call-gke-build-worker.yaml` (line 84-85)
- `.github/workflows/call-gke-build-db.yaml` (line 82-83)
- `.github/workflows/call-gke-build-redis.yaml` (line 82-83)

**Replace:**
```yaml
workload_identity_provider: 'projects/250238953270/locations/global/workloadIdentityPools/dadismad/providers/dadismad-github'
service_account: 'dadismad-github-actions@macro-truck-198415.iam.gserviceaccount.com'
```

**With your actual values** (from Step 6 output)

---

## 🔐 Part 4: Configure GitHub Secrets (5 minutes)

### Step 10: Add Secrets to GitHub

1. **Go to your GitHub repository**
   - https://github.com/dadismad-com/dadismad-voting-app

2. **Navigate to Settings → Secrets and variables → Actions**

3. **Click "New repository secret"**

4. **Add these 3 secrets:**

#### Secret 1: GKE_PROJECT
```
Name: GKE_PROJECT
Value: [Your PROJECT_ID from Step 6]
```

#### Secret 2: SECURE_API_TOKEN (Sysdig)

**If you have Sysdig:**
```
Name: SECURE_API_TOKEN
Value: [Your Sysdig API token]
```

**If you DON'T have Sysdig (skip scanning):**
- You'll need to remove the Sysdig scanning steps from workflows
- Or sign up at: https://sysdig.com/

#### Secret 3: SYSDIG_SECURE_URL

```
Name: SYSDIG_SECURE_URL
Value: https://us2.app.sysdig.com
(or your Sysdig region URL)
```

**No Sysdig? Skip scanning:**

If you don't want to use Sysdig, comment out these sections in all 5 workflow files:

```yaml
# Comment out or remove:
- name: Scan infrastructure
  uses: sysdiglabs/scan-action@v5
  # ...

- name: Scan image
  uses: sysdiglabs/scan-action@v5
  # ...
```

---

## 🚀 Part 5: First Deployment (5 minutes)

### Step 11: Commit and Push Changes

```bash
# Make sure you're in the repo directory
cd /Users/migueldelossantos/Downloads/dadismad-voting-app

# Check what changed
git status

# Add the updated files
git add k8s-specifications/
git add .github/workflows/

# Commit
git commit -m "Configure GKE connection with project-specific values

- Update Kubernetes deployments with actual PROJECT_ID
- Update workflows with Workload Identity configuration
- Ready for automated deployment"

# Push to trigger deployment
git push origin main
```

### Step 12: Watch the Deployment

1. **Go to GitHub Actions:**
   - https://github.com/dadismad-com/dadismad-voting-app/actions

2. **You should see "Deploy to GKE" workflow running**

3. **Click on it to watch progress:**
   - Detect changes ✓
   - Deploy DB ✓
   - Deploy Redis ✓
   - Deploy Vote, Result, Worker ✓

### Step 13: Verify Deployment in GKE

```bash
# Check if pods are running
kubectl get pods

# Expected output:
# NAME                      READY   STATUS    RESTARTS   AGE
# db-xxxxx                  1/1     Running   0          2m
# redis-xxxxx               1/1     Running   0          2m
# vote-xxxxx                1/1     Running   0          1m
# result-xxxxx              1/1     Running   0          1m
# worker-xxxxx              1/1     Running   0          1m

# Check services
kubectl get services

# Get external IPs (LoadBalancers)
kubectl get service vote -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
kubectl get service result -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Step 14: Access Your Application

```bash
# Get the external IPs
export VOTE_IP=$(kubectl get service vote -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export RESULT_IP=$(kubectl get service result -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Vote App:   http://$VOTE_IP"
echo "Result App: http://$RESULT_IP"

# Open in browser
open "http://$VOTE_IP"
open "http://$RESULT_IP"
```

**Note:** LoadBalancer provisioning takes 2-5 minutes. If you see `<pending>`, wait a bit and try again.

---

## ✅ Verification Checklist

After setup, verify everything works:

- [ ] **GCP Project created and billing enabled**
  ```bash
  gcloud projects describe $PROJECT_ID
  ```

- [ ] **GKE cluster running**
  ```bash
  kubectl get nodes
  # Should show 2+ nodes in Ready state
  ```

- [ ] **Artifact Registry exists**
  ```bash
  gcloud artifacts repositories list --location=us-central1
  ```

- [ ] **Service account has permissions**
  ```bash
  gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:dadismad-github-actions*"
  ```

- [ ] **Workload Identity configured**
  ```bash
  gcloud iam workload-identity-pools describe github-actions-pool \
    --location=global
  ```

- [ ] **GitHub secrets set**
  - Check in GitHub UI: Settings → Secrets → Actions

- [ ] **Workflows updated with correct values**
  ```bash
  grep "workload_identity_provider" .github/workflows/call-gke-build-vote.yaml
  grep "PROJECT_ID" k8s-specifications/vote-deployment.yaml
  ```

- [ ] **GitHub Actions workflow runs successfully**
  - Check: https://github.com/dadismad-com/dadismad-voting-app/actions

- [ ] **Pods running in GKE**
  ```bash
  kubectl get pods
  # All should show Running status
  ```

- [ ] **Services have external IPs**
  ```bash
  kubectl get services
  # vote and result should have EXTERNAL-IP
  ```

- [ ] **Applications accessible in browser**
  - Vote app loads
  - Result app loads
  - Can cast votes and see results

---

## 🔧 Troubleshooting

### Issue: "Billing not enabled"

```bash
# Check billing status
gcloud beta billing projects describe $PROJECT_ID

# Link billing account
gcloud beta billing projects link $PROJECT_ID \
  --billing-account=YOUR-BILLING-ACCOUNT-ID
```

### Issue: "Permission denied" in GitHub Actions

**Check Workload Identity configuration:**

```bash
# Verify pool exists
gcloud iam workload-identity-pools describe github-actions-pool \
  --location=global

# Verify provider exists
gcloud iam workload-identity-pools providers describe github-provider \
  --location=global \
  --workload-identity-pool=github-actions-pool

# Verify service account IAM binding
gcloud iam service-accounts get-iam-policy $SA_EMAIL
```

**Common fix:**

Make sure the GitHub repository name in the IAM binding matches exactly:

```bash
# Should be: your-org/your-repo (e.g., dadismad-com/dadismad-voting-app)
# Check current binding:
gcloud iam service-accounts get-iam-policy $SA_EMAIL

# If wrong, remove and re-add:
gcloud iam service-accounts remove-iam-policy-binding $SA_EMAIL \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/OLD-REPO-NAME"

gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/dadismad-com/dadismad-voting-app"
```

### Issue: "Failed to pull image"

**Grant GKE access to Artifact Registry:**

```bash
# Get GKE service account
export GKE_SA=$(gcloud iam service-accounts list \
  --filter="displayName:Compute Engine default service account" \
  --format="value(email)")

# Grant Artifact Registry reader permission
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${GKE_SA}" \
  --role="roles/artifactregistry.reader"
```

### Issue: Pods show "CrashLoopBackOff"

```bash
# Check pod logs
kubectl get pods
kubectl logs POD-NAME

# Common issues:
# 1. Database not ready - wait for db pod to be Running
# 2. Redis not ready - wait for redis pod to be Running
# 3. Environment variables wrong - check deployment.yaml

# Restart a deployment
kubectl rollout restart deployment vote
```

### Issue: LoadBalancer stuck on "Pending"

```bash
# Check service events
kubectl describe service vote

# LoadBalancers take 2-5 minutes to provision
# If stuck longer:
kubectl delete service vote
kubectl apply -f k8s-specifications/vote-service-lb.yaml
```

### Issue: Sysdig scanning fails

**Option 1: Remove Sysdig scanning**

Edit all 5 workflow files and comment out:

```yaml
# - name: Scan infrastructure
#   uses: sysdiglabs/scan-action@v5
#   with:
#     sysdig-secure-token: ${{ secrets.SECURE_API_TOKEN }}
#     sysdig-secure-url: ${{ secrets.SYSDIG_SECURE_URL }}
```

**Option 2: Sign up for Sysdig**

1. Go to https://sysdig.com/
2. Sign up for free trial
3. Get API token from Settings
4. Add to GitHub secrets

---

## 💰 Cost Estimate

### Development Setup
- **GKE Cluster:** ~$100/month (2 e2-standard-2 nodes)
- **LoadBalancers:** ~$20/month (2 external IPs)
- **Storage:** ~$2/month (10GB disk)
- **Artifact Registry:** Free tier
- **Total:** ~$120-130/month

### Production Setup
- **GKE Cluster:** ~$300/month (3+ n1-standard-2 nodes)
- **LoadBalancers:** ~$20/month
- **Storage:** ~$10/month (50GB + persistent disk)
- **Total:** ~$330-350/month

**Cost Saving Tips:**
- Use preemptible nodes (60-80% cheaper)
- Stop cluster when not needed
- Use smaller machine types for dev
- Delete old images from Artifact Registry

---

## 🎉 Success!

If everything is green:

✅ Your GitHub repository is connected to GKE  
✅ Automated deployments are working  
✅ Your voting app is running in Kubernetes  
✅ Every push to `main` triggers deployment  

**Test it:** Make a small change and push to see automatic deployment!

```bash
echo "# Test" >> vote/app.py
git add vote/app.py
git commit -m "Test: trigger deployment"
git push origin main

# Watch it deploy automatically at:
# https://github.com/dadismad-com/dadismad-voting-app/actions
```

---

## 📚 Next Steps

1. **Set up monitoring:** Enable Cloud Monitoring and Logging
2. **Add domain:** Configure Cloud DNS and SSL certificates
3. **Implement autoscaling:** Add Horizontal Pod Autoscaler
4. **Set up staging:** Create a staging namespace
5. **Configure backups:** Automate database backups
6. **Add alerts:** Set up alerting for failures

See [GKE_DEPLOYMENT.md](GKE_DEPLOYMENT.md) for production best practices!

---

**Questions?** Check [GKE_DEPLOYMENT.md](GKE_DEPLOYMENT.md) for detailed troubleshooting.

**Need help?** Review GitHub Actions logs and GKE pod logs for specific errors.
