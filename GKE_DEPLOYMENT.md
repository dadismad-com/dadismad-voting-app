# GKE Deployment Guide

Complete guide for deploying the Voting App to Google Kubernetes Engine (GKE) using GitHub Actions.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [GCP Setup](#gcp-setup)
- [GitHub Secrets Configuration](#github-secrets-configuration)
- [Workflow Architecture](#workflow-architecture)
- [Deployment Process](#deployment-process)
- [Manual Deployment](#manual-deployment)
- [Monitoring & Troubleshooting](#monitoring--troubleshooting)
- [Production Considerations](#production-considerations)

---

## 🎯 Overview

This repository uses GitHub Actions to automatically build Docker images, push them to Google Artifact Registry (GAR), and deploy them to GKE.

### Architecture

```
GitHub Push → Detect Changes → Build Images → Scan Images → Push to GAR → Deploy to GKE
```

### Services Deployed

| Service | Type | Deployment Order |
|---------|------|------------------|
| PostgreSQL | Infrastructure | 1 |
| Redis | Infrastructure | 1 |
| Vote | Application | 2 |
| Result | Application | 2 |
| Worker | Application | 2 |

---

## ✅ Prerequisites

### Required Tools

- **Google Cloud Account** with billing enabled
- **GCP Project** created
- **GKE Cluster** provisioned
- **Artifact Registry** repository created
- **GitHub Repository** with Actions enabled

### GCP Services Required

- Google Kubernetes Engine (GKE)
- Google Artifact Registry (GAR)
- Workload Identity Federation
- IAM Service Accounts

---

## 🔧 GCP Setup

### Step 1: Create GCP Project

```bash
# Set your project ID
export PROJECT_ID="your-project-id"

# Create project (if new)
gcloud projects create $PROJECT_ID

# Set as active project
gcloud config set project $PROJECT_ID
```

### Step 2: Enable Required APIs

```bash
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com \
  iam.googleapis.com
```

### Step 3: Create Artifact Registry Repository

```bash
# Create repository for Docker images
gcloud artifacts repositories create dadismad \
  --repository-format=docker \
  --location=us-central1 \
  --description="Voting app Docker images"
```

### Step 4: Create GKE Cluster

```bash
# Create GKE cluster
gcloud container clusters create dadismad-cluster-1 \
  --zone us-central1 \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --enable-autoscaling \
  --min-nodes 3 \
  --max-nodes 10 \
  --enable-autorepair \
  --enable-autoupgrade

# Get cluster credentials
gcloud container clusters get-credentials dadismad-cluster-1 \
  --zone us-central1
```

### Step 5: Create Service Account for GitHub Actions

```bash
# Create service account
gcloud iam service-accounts create dadismad-github-actions \
  --display-name="GitHub Actions Service Account" \
  --description="Service account for GitHub Actions deployments"

# Get the email
export SA_EMAIL="dadismad-github-actions@${PROJECT_ID}.iam.gserviceaccount.com"

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.developer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer"
```

### Step 6: Configure Workload Identity Federation

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "dadismad" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Get the pool ID
export WORKLOAD_IDENTITY_POOL_ID=$(gcloud iam workload-identity-pools describe dadismad \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)")

# Create provider for GitHub
gcloud iam workload-identity-pools providers create-oidc "dadismad-github" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="dadismad" \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Get provider ID
export PROVIDER_ID=$(gcloud iam workload-identity-pools providers describe dadismad-github \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="dadismad" \
  --format="value(name)")

# Allow GitHub Actions to impersonate service account
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/dadismad-com/dadismad-voting-app"
```

---

## 🔐 GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

### Required Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `GKE_PROJECT` | GCP Project ID | `macro-truck-198415` |
| `SECURE_API_TOKEN` | Sysdig security token | `your-sysdig-token` |
| `SYSDIG_SECURE_URL` | Sysdig API URL | `https://us2.app.sysdig.com` |

### Workload Identity Configuration

Update the workflows with your specific values:

```yaml
workload_identity_provider: 'projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/dadismad/providers/dadismad-github'
service_account: 'dadismad-github-actions@PROJECT_ID.iam.gserviceaccount.com'
```

**To get your project number:**

```bash
gcloud projects describe $PROJECT_ID --format="value(projectNumber)"
```

---

## 🏗️ Workflow Architecture

### Main Workflow: `deploy-to-gke.yaml`

Orchestrates all deployments with smart change detection.

**Triggers:**
- Push to `main` branch (with path filters)
- Manual dispatch with "deploy all" option

**Process:**
1. **Detect Changes** - Identifies which services changed
2. **Deploy Infrastructure** - Deploys DB and Redis first
3. **Deploy Applications** - Deploys Vote, Result, Worker in parallel
4. **Summary** - Reports deployment status

### Individual Workflows

| Workflow | Purpose | Image Built |
|----------|---------|-------------|
| `call-gke-build-vote.yaml` | Deploy vote service | `us-central1-docker.pkg.dev/PROJECT_ID/dadismad/vote:latest` |
| `call-gke-build-result.yaml` | Deploy result service | `us-central1-docker.pkg.dev/PROJECT_ID/dadismad/result:latest` |
| `call-gke-build-worker.yaml` | Deploy worker service | `us-central1-docker.pkg.dev/PROJECT_ID/dadismad/worker:latest` |
| `call-gke-build-db.yaml` | Deploy PostgreSQL | Uses `postgres:15-alpine` |
| `call-gke-build-redis.yaml` | Deploy Redis | Uses `redis:alpine` |

### Workflow Features

- ✅ **Smart Change Detection** - Only builds what changed
- ✅ **Dependency Management** - Infrastructure deploys first
- ✅ **Security Scanning** - Sysdig scans images and infrastructure
- ✅ **Parallel Deployment** - Application services deploy simultaneously
- ✅ **Health Checks** - All services have liveness and readiness probes
- ✅ **Resource Limits** - CPU and memory limits configured

---

## 🚀 Deployment Process

### Automatic Deployment

Deployments trigger automatically when you push to `main`:

```bash
# Make changes to vote service
git add vote/
git commit -m "Update vote service"
git push origin main

# GitHub Actions will:
# 1. Detect vote/ changed
# 2. Build vote Docker image
# 3. Scan image for vulnerabilities
# 4. Push to Artifact Registry
# 5. Deploy to GKE
```

### Path-Based Triggers

Changes are automatically detected based on file paths:

| Path Changed | Services Deployed |
|--------------|-------------------|
| `vote/**` | Vote service only |
| `result/**` | Result service only |
| `worker/**` | Worker service only |
| `k8s-specifications/db-*.yaml` | Database |
| `k8s-specifications/redis-*.yaml` | Redis |
| Multiple paths | All affected services |

### Manual Deployment

Deploy all services manually:

1. Go to **Actions** tab in GitHub
2. Select **Deploy to GKE** workflow
3. Click **Run workflow**
4. Check **Deploy all services** checkbox
5. Click **Run workflow** button

Or deploy individual services:

1. Go to **Actions** tab
2. Select specific service workflow (e.g., `Call GKE Build to Deploy Vote`)
3. Click **Run workflow**

---

## 📦 Kubernetes Resources

### Deployments

All deployments include:

- **Health Checks** - Liveness and readiness probes
- **Resource Limits** - CPU and memory constraints
- **Labels** - For service discovery
- **Replicas** - Vote: 2, Others: 1

### Services

| Service | Type | Port | External |
|---------|------|------|----------|
| vote | LoadBalancer | 80 | Yes |
| result | LoadBalancer | 80 | Yes |
| db | ClusterIP | 5432 | No |
| redis | ClusterIP | 6379 | No |

### Persistent Storage

**Database:** Uses PersistentVolumeClaim (10Gi)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-data-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

**Redis:** Uses emptyDir (temporary storage)

---

## 🔍 Monitoring & Troubleshooting

### Check Deployment Status

```bash
# Get deployments
kubectl get deployments

# Get pods
kubectl get pods

# Get services
kubectl get services

# Check specific deployment
kubectl describe deployment vote
```

### View Logs

```bash
# View logs from specific service
kubectl logs -l app=vote --tail=50 -f

# View logs from specific pod
kubectl logs pod-name -f

# View previous logs (if pod crashed)
kubectl logs pod-name --previous
```

### Check GitHub Actions

1. Go to **Actions** tab in repository
2. Click on specific workflow run
3. View job details and logs
4. Check for errors in:
   - Authentication
   - Docker build
   - Image scanning
   - Kubernetes apply

### Common Issues

#### Issue: Authentication Failed

**Error:** `Failed to authenticate to Google Cloud`

**Solution:**
- Verify Workload Identity Federation is configured correctly
- Check service account has necessary permissions
- Verify GitHub secrets are set correctly

#### Issue: Image Pull Errors

**Error:** `Failed to pull image from Artifact Registry`

**Solution:**
```bash
# Grant Artifact Registry reader role to GKE service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$(gcloud iam service-accounts list --filter='displayName:Compute Engine default service account' --format='value(email)')" \
  --role="roles/artifactregistry.reader"
```

#### Issue: Pod CrashLoopBackOff

**Solution:**
```bash
# Check pod logs
kubectl logs pod-name --previous

# Describe pod for events
kubectl describe pod pod-name

# Check resource limits
kubectl top pods
```

#### Issue: Service Not Accessible

**Solution:**
```bash
# Check service endpoints
kubectl get endpoints

# Check if pods are ready
kubectl get pods

# Verify LoadBalancer got external IP
kubectl get services
```

---

## 🏭 Production Considerations

### Before Going to Production

#### Security

- [ ] **Secrets Management**
  ```bash
  # Use GCP Secret Manager instead of environment variables
  kubectl create secret generic db-credentials \
    --from-literal=username=postgres \
    --from-literal=password=YOUR_SECURE_PASSWORD
  ```

- [ ] **Network Policies**
  ```yaml
  # Restrict pod-to-pod communication
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
    name: allow-specific
  spec:
    podSelector:
      matchLabels:
        app: vote
    policyTypes:
    - Ingress
    - Egress
    ingress:
    - from:
      - podSelector:
          matchLabels:
            app: vote
  ```

- [ ] **TLS/SSL**
  - Enable HTTPS on LoadBalancer services
  - Use Google-managed certificates
  - Configure Ingress with TLS

#### High Availability

- [ ] **Increase Replicas**
  ```yaml
  spec:
    replicas: 3  # Increase from 1
  ```

- [ ] **Pod Disruption Budgets**
  ```yaml
  apiVersion: policy/v1
  kind: PodDisruptionBudget
  metadata:
    name: vote-pdb
  spec:
    minAvailable: 2
    selector:
      matchLabels:
        app: vote
  ```

- [ ] **Multi-Zone Deployment**
  ```bash
  # Create regional cluster instead of zonal
  gcloud container clusters create dadismad-cluster-1 \
    --region us-central1 \
    --num-nodes 3
  ```

#### Database

- [ ] **Cloud SQL**
  - Use Cloud SQL for PostgreSQL instead of in-cluster database
  - Automatic backups and high availability
  - Better performance and reliability

- [ ] **Database Backups**
  ```bash
  # Schedule automated backups
  kubectl create cronjob db-backup \
    --image=postgres:15-alpine \
    --schedule="0 2 * * *" \
    -- /bin/sh -c "pg_dump..."
  ```

#### Monitoring

- [ ] **Google Cloud Monitoring**
  ```bash
  # Enable monitoring
  gcloud container clusters update dadismad-cluster-1 \
    --enable-cloud-monitoring \
    --zone us-central1
  ```

- [ ] **Logging**
  ```bash
  # Enable logging
  gcloud container clusters update dadismad-cluster-1 \
    --enable-cloud-logging \
    --zone us-central1
  ```

- [ ] **Alerting**
  - Set up alerts for high CPU/memory usage
  - Alert on pod failures
  - Alert on service unavailability

#### Cost Optimization

- [ ] **Autoscaling**
  ```yaml
  apiVersion: autoscaling/v2
  kind: HorizontalPodAutoscaler
  metadata:
    name: vote-hpa
  spec:
    scaleTargetRef:
      apiVersion: apps/v1
      kind: Deployment
      name: vote
    minReplicas: 2
    maxReplicas: 10
    metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
  ```

- [ ] **Resource Optimization**
  - Right-size resource requests and limits
  - Use node auto-provisioning
  - Enable cluster autoscaling

---

## 🔄 CI/CD Best Practices

### Versioning

Instead of using `latest` tag, use semantic versioning:

```yaml
IMAGE_TAG: v1.0.${{ github.run_number }}
```

### Rollback Strategy

```bash
# View deployment history
kubectl rollout history deployment/vote

# Rollback to previous version
kubectl rollout undo deployment/vote

# Rollback to specific revision
kubectl rollout undo deployment/vote --to-revision=2
```

### Staging Environment

Create a staging environment:

```bash
# Create staging namespace
kubectl create namespace staging

# Deploy to staging first
kubectl apply -f k8s-specifications/ -n staging
```

---

## 📚 Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Artifact Registry Documentation](https://cloud.google.com/artifact-registry/docs)
- [Workload Identity Documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kubernetes Documentation](https://kubernetes.io/docs)

---

## 🆘 Support

For issues with:
- **GitHub Actions**: Check workflow logs and [CODE_REVIEW_REPORT.md](CODE_REVIEW_REPORT.md)
- **GKE**: Use `kubectl describe` and `kubectl logs` for debugging
- **GCP**: Check Cloud Console logs and IAM permissions

---

**Last Updated:** 2026-01-22  
**Maintained by:** dadismad-com
