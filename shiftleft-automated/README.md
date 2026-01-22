# Upwind Shift Left Automated Scanning

This repository contains the automated security scanning workflow for Upwind Shift Left integration.

## 🎯 Purpose

This workflow is automatically triggered by the Upwind GitHub App whenever a Docker image is pushed to your container registry. It performs security scanning on the image and reports findings to the Upwind Console.

## 🔧 How It Works

1. **Upwind GitHub App** monitors GitHub Actions workflows in your organization
2. When it detects a Docker image push, it triggers this workflow
3. The workflow:
   - Authenticates to GCP Artifact Registry
   - Pulls the Docker image
   - Runs Upwind security scan
   - Reports findings to Upwind Console

## 📋 Prerequisites

### 1. Upwind Credentials
You need Upwind Sensor credentials with:
- `UPWIND_CLIENT_ID` - Your Upwind client ID
- `UPWIND_CLIENT_SECRET` - Your Upwind client secret

### 2. GitHub Secrets
Add these secrets to this repository (Settings → Secrets → Actions):

| Secret Name | Description |
|-------------|-------------|
| `UPWIND_CLIENT_ID` | Upwind client ID for authentication |
| `UPWIND_CLIENT_SECRET` | Upwind client secret for authentication |

### 3. GCP Access
This workflow uses Workload Identity Federation to access GCP Artifact Registry. Ensure:
- The service account has `artifactregistry.reader` role
- Workload Identity Pool is configured for this repository

## 🚀 Setup Instructions

### Step 1: Create This Repository

This repository **must** be named `shiftleft-automated` and exist at:
```
https://github.com/YOUR-ORG/shiftleft-automated
```

### Step 2: Add GitHub Secrets

1. Go to: Settings → Secrets and variables → Actions
2. Add the two Upwind secrets (see Prerequisites above)

### Step 3: Update Configuration

If your GCP project ID is different, update the service account in `.github/workflows/scan-image.yaml`:

```yaml
service_account: 'dadismad-github-actions@YOUR_PROJECT_ID.iam.gserviceaccount.com'
```

### Step 4: Install Upwind GitHub App

1. Visit [Upwind GitHub Marketplace](https://github.com/marketplace)
2. Search for "Upwind Security"
3. Click "Set up a plan"
4. Choose your organization
5. Select repository access:
   - **Recommended:** All repositories (to scan all images)
   - **Or:** Select specific repositories (must include this repo)
6. Review and approve permissions
7. Complete installation

### Step 5: Verify Setup

Test the workflow manually:

1. Go to: Actions → Upwind Shift Left Scanning
2. Click "Run workflow"
3. Enter test parameters:
   - **image_name**: `us-central1-docker.pkg.dev/PROJECT_ID/dadismad/vote:latest`
   - **repo**: `dadismad-voting-app`
   - **run_id**: `123456`
4. Click "Run workflow"
5. Check Upwind Console for scan results

## 📊 Monitoring

### View Scan Results

**Upwind Console:**
- Navigate to: Vulnerabilities → Shift Left
- View all scanned images and findings

**GitHub Actions:**
- Go to: Actions tab in this repository
- View individual workflow runs

### Scan Triggers

The workflow is triggered automatically when:
- A Docker image is pushed to your registry
- The Upwind GitHub App detects the push event
- The workflow is called with image details

## 🔒 Security Notes

### Permissions
This workflow requires:
- `actions: read` - Read workflow metadata
- `contents: read` - Access repository contents
- `id-token: write` - Generate OIDC tokens for GCP auth
- `pull-requests: write` - Comment on PRs (optional)

### Credentials
- Upwind credentials are stored as GitHub secrets
- GCP authentication uses Workload Identity (no keys!)
- Docker images are pulled temporarily and not stored

### Image Access
- Only images your service account can access are scanned
- Scans happen in isolated GitHub runners
- No image data leaves your organization

## 🛠️ Troubleshooting

### Workflow Not Triggering

**Check:**
1. Upwind GitHub App is installed
2. App has access to source repositories
3. App has access to this repository
4. Images are actually being pushed to registry

### Authentication Failures

**GCP Authentication:**
```bash
# Verify Workload Identity Pool
gcloud iam workload-identity-pools providers describe github-provider \
  --workload-identity-pool=github-actions-pool \
  --location=global

# Verify service account access
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:dadismad-github-actions@*"
```

**Upwind Authentication:**
- Verify client ID and secret are correct
- Check secrets are set in repository settings
- Ensure credentials haven't expired

### Image Pull Failures

**Registry Access:**
```yaml
# Check service account has artifactregistry.reader
# Add if missing:
gcloud artifacts repositories add-iam-policy-binding dadismad \
  --location=us-central1 \
  --member="serviceAccount:dadismad-github-actions@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

### Scan Failures

**Common Issues:**
- Image doesn't exist or wrong name
- Image format not supported
- Upwind API connectivity issues
- Rate limiting

**Debug:**
1. Check workflow logs in Actions tab
2. Verify image exists: `docker pull IMAGE_NAME`
3. Check Upwind Console for errors
4. Contact Upwind support if persistent

## 📚 Additional Resources

- [Upwind Documentation](https://docs.upwind.io/)
- [Upwind GitHub Action](https://github.com/upwindsecurity/shiftleft-create-image-scan-event-action)
- [GCP Workload Identity](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions Documentation](https://docs.github.com/actions)

## 🔄 Updates

This workflow is maintained as part of the `dadismad-voting-app` deployment infrastructure.

**To update:**
1. Make changes to `.github/workflows/scan-image.yaml`
2. Test manually using "Run workflow"
3. Commit and push changes
4. Future scans will use updated workflow

---

**Questions?** See main project README or contact your security team.
