# 🚀 START HERE - Connect GitHub to GKE

**Your Goal:** Automatically deploy the voting app to Google Kubernetes Engine when you push to GitHub

**Status:** ✅ Workflows are configured. You just need to set up Google Cloud.

---

## ⚡ Choose Your Path

### Option 1: Automated (15 minutes) - RECOMMENDED

**Run one script and it does everything:**

```bash
./setup-gke.sh
```

Then follow the prompts. The script will:
- Create GCP project
- Set up GKE cluster
- Configure all permissions
- Update your files
- Generate configuration

**After the script completes:**
1. Add 3 secrets to GitHub (instructions shown by script)
2. Commit and push
3. Watch your app deploy!

**See:** [QUICKSTART_GKE.md](QUICKSTART_GKE.md)

---

### Option 2: Manual (45 minutes) - Learn Every Step

**Follow the detailed guide to understand each step:**

**See:** [SETUP_GKE_CONNECTION.md](SETUP_GKE_CONNECTION.md)

You'll manually:
- Create GCP project and enable APIs
- Create GKE cluster
- Set up Artifact Registry
- Configure Workload Identity
- Update repository files
- Add GitHub secrets

---

## 📋 Prerequisites (Both Options)

### 1. Google Cloud Account
- Sign up: https://cloud.google.com/free
- **Must enable billing** (required for GKE)
- Get $300 free credits for new accounts

### 2. Install gcloud CLI

**Mac:**
```bash
brew install --cask google-cloud-sdk
```

**Other:** https://cloud.google.com/sdk/docs/install

### 3. Install kubectl

**Mac:**
```bash
brew install kubectl
```

**Other:** https://kubernetes.io/docs/tasks/tools/

### 4. Login to Google Cloud

```bash
gcloud auth login
gcloud auth application-default login
```

### 5. Find Your Billing Account ID

1. Go to: https://console.cloud.google.com/billing
2. Copy your Billing Account ID (format: `XXXXXX-XXXXXX-XXXXXX`)
3. You'll need this for the setup

---

## 🎯 Quick Start (Automated Path)

### Step 1: Run Setup Script

```bash
# Make executable
chmod +x setup-gke.sh

# Run it
./setup-gke.sh
```

**You'll be asked for:**
1. GCP Project ID (can generate new one)
2. Billing Account ID (from prerequisites)
3. GitHub repository name (e.g., `dadismad-com/dadismad-voting-app`)
4. Cluster type (Development or Production)

### Step 2: Add GitHub Secrets

The script will tell you exactly what to add.

Go to: `https://github.com/YOUR-ORG/dadismad-voting-app/settings/secrets/actions`

Add these 3 secrets:

**Secret 1: GKE_PROJECT**
```
Name: GKE_PROJECT
Value: [Your project ID from setup script]
```

**Secret 2: SECURE_API_TOKEN** (Optional - for security scanning)
```
Name: SECURE_API_TOKEN
Value: [Your Sysdig token, or skip for now]
```

**Secret 3: SYSDIG_SECURE_URL** (Optional)
```
Name: SYSDIG_SECURE_URL
Value: https://us2.app.sysdig.com
```

**Don't have Sysdig?** That's okay! You can:
- Skip it (workflows will still work)
- Comment out the scanning steps in workflows
- Or sign up at https://sysdig.com/

### Step 3: Commit and Push

```bash
# Add updated files
git add k8s-specifications/ .github/workflows/ gke-config.txt

# Commit
git commit -m "Configure GKE deployment"

# Push - this triggers deployment!
git push origin main
```

### Step 4: Watch Deployment

Go to: https://github.com/YOUR-ORG/dadismad-voting-app/actions

You should see "Deploy to GKE" workflow running!

### Step 5: Access Your App

```bash
# Wait for deployment to complete (5-10 minutes)
# Then get the external IPs:

kubectl get services

# Open apps in browser:
kubectl get service vote -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
kubectl get service result -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## ✅ Verification

After setup, verify everything works:

```bash
# Check cluster connection
kubectl get nodes
# Should show 2+ nodes in Ready state

# Check pods
kubectl get pods
# All should show Running status

# Check services
kubectl get services
# vote and result should have EXTERNAL-IP
```

---

## 💡 What Gets Created

### In Google Cloud:
- ✅ GCP Project
- ✅ GKE Cluster (2-3 nodes)
- ✅ Artifact Registry (Docker images)
- ✅ Service Account (for GitHub Actions)
- ✅ Workload Identity Federation (GitHub ↔ GCP auth)

### In Your Repository:
- ✅ Updated Kubernetes deployments with your project ID
- ✅ Updated GitHub Actions workflows with your credentials
- ✅ Configuration file: `gke-config.txt`

### On GitHub:
- ✅ Secrets for authentication
- ✅ Workflows ready to deploy automatically

---

## 💰 Cost Estimate

### Development Cluster:
- **~$100-130/month**
- 2 nodes (e2-standard-2)
- Good for testing

### Production Cluster:
- **~$300-350/month**
- 3+ nodes (n1-standard-2)
- Regional high availability
- Auto-scaling

**Free Tier:**
- New GCP accounts get $300 free credits
- Valid for 90 days

**Save Money:**
```bash
# Delete cluster when not needed
gcloud container clusters delete dadismad-cluster-1 --zone us-central1-a
```

---

## 🔧 Troubleshooting

### Setup script fails

**Check:**
1. gcloud is installed: `gcloud --version`
2. You're logged in: `gcloud auth list`
3. Billing is enabled: Check console.cloud.google.com/billing

### GitHub Actions fails

**Check:**
1. All 3 secrets are added to GitHub
2. Project ID is correct in secrets
3. Workload Identity is configured (script does this)

### Pods won't start

**Check:**
```bash
# View pod logs
kubectl logs POD-NAME

# Common issues:
# - Database not ready (wait 2-3 minutes)
# - Image pull failed (grant GKE access to Artifact Registry)
```

### Can't access app

**Check:**
```bash
# LoadBalancers take 2-5 minutes to get IPs
kubectl get services

# If stuck on "pending":
kubectl describe service vote
```

---

## 📚 Documentation

| File | Purpose | Size |
|------|---------|------|
| **START_HERE.md** (this file) | Quick overview | 🟢 |
| **QUICKSTART_GKE.md** | 15-min setup guide | 🟢 |
| **SETUP_GKE_CONNECTION.md** | Detailed step-by-step | 🔵 |
| **GKE_DEPLOYMENT.md** | Production guide | 🔵 |
| **DEPLOYMENT_CHANGES.md** | What was changed | 🟡 |
| **setup-gke.sh** | Automated setup script | ⚡ |

---

## 🎯 Success Criteria

You're done when:

- [ ] GKE cluster is running
- [ ] GitHub secrets are configured
- [ ] Workflow runs successfully
- [ ] All pods show "Running"
- [ ] Services have external IPs
- [ ] Vote app loads in browser
- [ ] Result app loads in browser
- [ ] Can cast votes and see results
- [ ] Pushing changes triggers auto-deployment

---

## 🆘 Need Help?

1. **Quick issues:** Check [QUICKSTART_GKE.md](QUICKSTART_GKE.md) troubleshooting
2. **Detailed help:** See [SETUP_GKE_CONNECTION.md](SETUP_GKE_CONNECTION.md) Part 6
3. **Production setup:** Review [GKE_DEPLOYMENT.md](GKE_DEPLOYMENT.md)
4. **Check logs:**
   ```bash
   kubectl logs POD-NAME
   kubectl describe pod POD-NAME
   ```

---

## 🚀 Ready to Go!

**Fastest path:** Run `./setup-gke.sh` and follow the prompts!

**Time to deployment:** 15-20 minutes

**Let's do this! 💪**
