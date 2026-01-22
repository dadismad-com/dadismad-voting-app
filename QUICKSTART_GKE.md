# 🚀 Quick Start: Deploy to GKE in 15 Minutes

The absolute fastest way to get your voting app running on Google Kubernetes Engine.

---

## ⚡ Super Quick Setup

### Prerequisites (5 minutes to install)

1. **Google Cloud Account**
   - Sign up: https://cloud.google.com/free
   - Enable billing

2. **Install gcloud CLI**
   ```bash
   # Mac
   brew install --cask google-cloud-sdk
   
   # Or download from:
   # https://cloud.google.com/sdk/docs/install
   ```

3. **Install kubectl**
   ```bash
   # Mac
   brew install kubectl
   
   # Or download from:
   # https://kubernetes.io/docs/tasks/tools/
   ```

4. **Login to Google Cloud**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

---

## 🎯 Option 1: Automated Setup (Recommended)

**Run ONE unified script that handles both new AND existing projects!**

```bash
# Run the setup
./setup-gke.sh
```

**The script will ask you:**
1. Use EXISTING project or create NEW one?
2. Project ID (shows list if existing)
3. Billing account ID (if needed)
4. GitHub repository name
5. Development or Production cluster

**Then it automatically:**
- ✅ Creates GCP project
- ✅ Enables APIs
- ✅ Creates Artifact Registry
- ✅ Creates GKE cluster
- ✅ Sets up Service Account
- ✅ Configures Workload Identity
- ✅ Updates all your files
- ✅ Generates configuration

**Time: ~10 minutes**

---

## 🛠️ Option 2: Manual Setup

Follow the detailed guide: **[SETUP_GKE_CONNECTION.md](SETUP_GKE_CONNECTION.md)**

---

## 📝 After Setup: Configure GitHub

### 1. Add GitHub Secrets

Go to: `https://github.com/YOUR-ORG/dadismad-voting-app/settings/secrets/actions`

Add this secret:

| Secret Name | Value |
|-------------|-------|
| `GKE_PROJECT` | Your GCP Project ID (from setup) |

### 2. Commit and Push

```bash
# Add updated files
git add k8s-specifications/ .github/workflows/ gke-config.txt

# Commit
git commit -m "Configure GKE deployment"

# Push (this triggers deployment!)
git push origin main
```

### 3. Watch Deployment

Go to: `https://github.com/YOUR-ORG/dadismad-voting-app/actions`

You should see "Deploy to GKE" running!

---

## ✅ Verify Deployment

### Check Pods

```bash
# All pods should be Running
kubectl get pods

# Expected output:
# NAME                      READY   STATUS    RESTARTS   AGE
# db-xxxxx                  1/1     Running   0          2m
# redis-xxxxx               1/1     Running   0          2m
# vote-xxxxx                1/1     Running   0          1m
# result-xxxxx              1/1     Running   0          1m
# worker-xxxxx              1/1     Running   0          1m
```

### Get External IPs

```bash
# Get services
kubectl get services

# Get vote app URL
kubectl get service vote -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Get result app URL
kubectl get service result -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

**Note:** LoadBalancer IPs take 2-5 minutes to provision.

### Access Applications

```bash
# Vote app
open "http://$(kubectl get service vote -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"

# Result app
open "http://$(kubectl get service result -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
```

---

## 🎉 Success Checklist

- [ ] GKE cluster created and running
- [ ] GitHub secrets configured
- [ ] Files committed and pushed
- [ ] GitHub Actions workflow completed successfully
- [ ] All pods showing `Running` status
- [ ] Services have external IPs
- [ ] Vote app loads in browser
- [ ] Result app loads in browser
- [ ] Can cast votes and see results

---

## 🔧 Quick Troubleshooting

### Problem: GitHub Actions fails with "authentication failed"

**Fix:** Check that GitHub secrets are set correctly:
- `GKE_PROJECT` should be your project ID
- Workload Identity Provider in workflows is correct
- Service account email is correct

### Problem: Pods show "ImagePullBackOff"

**Fix:** Grant GKE access to Artifact Registry:

```bash
export PROJECT_ID="your-project-id"
export GKE_SA=$(gcloud iam service-accounts list \
  --filter="displayName:Compute Engine default service account" \
  --format="value(email)")

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${GKE_SA}" \
  --role="roles/artifactregistry.reader"
```

### Problem: LoadBalancer stuck on "Pending"

**Wait 2-5 minutes** - LoadBalancers take time to provision.

If still pending after 10 minutes:

```bash
kubectl describe service vote
kubectl delete service vote
kubectl apply -f k8s-specifications/vote-service-lb.yaml
```

### Problem: Pods show "CrashLoopBackOff"

```bash
# Check logs
kubectl logs <pod-name>

# Common fixes:
# 1. Wait for db and redis to be Running first
# 2. Check environment variables in deployment
# 3. Restart deployment:
kubectl rollout restart deployment <name>
```

---

## 💰 Cost Warning

Running this on GKE costs money:

- **Development:** ~$100-130/month
- **Production:** ~$300-350/month

**Save money:**
- Delete cluster when not needed: `gcloud container clusters delete dadismad-cluster-1 --zone us-central1-a`
- Use smaller machine types
- Use preemptible nodes (60% cheaper)

---

## 🧪 Test Automated Deployment

Make a change and push to test automatic deployment:

```bash
# Make a small change
echo "# Test deployment" >> vote/app.py

# Commit and push
git add vote/app.py
git commit -m "Test: trigger auto-deployment"
git push origin main

# Watch it deploy at:
# https://github.com/YOUR-ORG/dadismad-voting-app/actions
```

Only the vote service should rebuild and deploy!

---

## 📚 More Information

- **Detailed Setup:** [SETUP_GKE_CONNECTION.md](SETUP_GKE_CONNECTION.md)
- **Deployment Guide:** [GKE_DEPLOYMENT.md](GKE_DEPLOYMENT.md)
- **Changes Made:** [DEPLOYMENT_CHANGES.md](DEPLOYMENT_CHANGES.md)

---

## 🆘 Need Help?

1. Check logs: `kubectl logs <pod-name>`
2. Check events: `kubectl describe pod <pod-name>`
3. Check GitHub Actions logs
4. Review [SETUP_GKE_CONNECTION.md](SETUP_GKE_CONNECTION.md) troubleshooting section

---

**Time from zero to deployed:** ~15 minutes ⚡

**Cost:** ~$100-300/month 💰

**Difficulty:** Easy 🟢

**Let's go! 🚀**
