#!/bin/bash

# GKE Setup Script for Voting App
# This script automates the Google Cloud setup for GitHub Actions deployment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    echo "Install from: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

print_header "GKE Setup for Voting App"

# Get user inputs
echo -e "${BLUE}This script will set up Google Cloud for automated deployments${NC}\n"

read -p "Enter your GCP Project ID (or press Enter for new project): " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    PROJECT_ID="dadismad-voting-$(date +%s)"
    print_info "Using generated project ID: $PROJECT_ID"
else
    print_info "Using project ID: $PROJECT_ID"
fi

read -p "Enter your billing account ID (find at console.cloud.google.com/billing): " BILLING_ACCOUNT

if [ -z "$BILLING_ACCOUNT" ]; then
    print_error "Billing account is required"
    exit 1
fi

read -p "GitHub repository (e.g., dadismad-com/dadismad-voting-app): " GITHUB_REPO

if [ -z "$GITHUB_REPO" ]; then
    print_error "GitHub repository is required"
    exit 1
fi

echo ""
read -p "Choose cluster type - (1) Development (cheaper) or (2) Production (regional HA): " CLUSTER_TYPE

if [ "$CLUSTER_TYPE" = "1" ]; then
    CLUSTER_ZONE="us-central1-a"
    CLUSTER_REGION=""
    IS_REGIONAL=false
    print_info "Will create zonal development cluster"
else
    CLUSTER_ZONE=""
    CLUSTER_REGION="us-central1"
    IS_REGIONAL=true
    print_info "Will create regional production cluster"
fi

echo ""
print_warning "This will create resources that incur costs (~$100-300/month)"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Setup cancelled"
    exit 0
fi

# Start setup
print_header "Step 1: Creating GCP Project"

# Check if project exists
if gcloud projects describe $PROJECT_ID &> /dev/null; then
    print_info "Project already exists: $PROJECT_ID"
else
    print_info "Creating project: $PROJECT_ID"
    gcloud projects create $PROJECT_ID --name="Voting App"
    print_success "Project created"
fi

# Set active project
gcloud config set project $PROJECT_ID

# Link billing
print_info "Linking billing account..."
gcloud beta billing projects link $PROJECT_ID \
  --billing-account=$BILLING_ACCOUNT 2>&1 | grep -v "WARNING" || true
print_success "Billing linked"

print_header "Step 2: Enabling APIs"

print_info "Enabling required APIs (takes ~2 minutes)..."
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  compute.googleapis.com \
  --quiet

print_success "APIs enabled"

print_header "Step 3: Creating Artifact Registry"

# Check if repository exists
if gcloud artifacts repositories describe dadismad --location=us-central1 &> /dev/null; then
    print_info "Artifact Registry already exists"
else
    print_info "Creating Artifact Registry..."
    gcloud artifacts repositories create dadismad \
      --repository-format=docker \
      --location=us-central1 \
      --description="Voting app Docker images"
    print_success "Artifact Registry created"
fi

print_header "Step 4: Creating GKE Cluster"

# Check if cluster exists
if gcloud container clusters describe dadismad-cluster-1 --zone=$CLUSTER_ZONE --region=$CLUSTER_REGION &> /dev/null; then
    print_info "GKE cluster already exists"
else
    if [ "$IS_REGIONAL" = true ]; then
        print_info "Creating regional GKE cluster (this takes 5-10 minutes)..."
        gcloud container clusters create dadismad-cluster-1 \
          --region $CLUSTER_REGION \
          --num-nodes 1 \
          --machine-type n1-standard-2 \
          --disk-size 50GB \
          --enable-autoscaling \
          --min-nodes 3 \
          --max-nodes 10 \
          --enable-autorepair \
          --enable-autoupgrade \
          --enable-ip-alias \
          --quiet
    else
        print_info "Creating zonal GKE cluster (this takes 3-5 minutes)..."
        gcloud container clusters create dadismad-cluster-1 \
          --zone $CLUSTER_ZONE \
          --num-nodes 2 \
          --machine-type e2-standard-2 \
          --disk-size 20GB \
          --enable-autoscaling \
          --min-nodes 2 \
          --max-nodes 4 \
          --enable-autorepair \
          --enable-autoupgrade \
          --enable-ip-alias \
          --quiet
    fi
    print_success "GKE cluster created"
fi

# Get credentials
print_info "Getting cluster credentials..."
if [ "$IS_REGIONAL" = true ]; then
    gcloud container clusters get-credentials dadismad-cluster-1 --region $CLUSTER_REGION
else
    gcloud container clusters get-credentials dadismad-cluster-1 --zone $CLUSTER_ZONE
fi
print_success "Connected to cluster"

print_header "Step 5: Creating Service Account"

SA_NAME="dadismad-github-actions"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Check if service account exists
if gcloud iam service-accounts describe $SA_EMAIL &> /dev/null; then
    print_info "Service account already exists"
else
    print_info "Creating service account..."
    gcloud iam service-accounts create $SA_NAME \
      --display-name="GitHub Actions Deployment SA" \
      --description="Service account for automated deployments from GitHub Actions"
    print_success "Service account created"
fi

# Grant permissions
print_info "Granting permissions..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.developer" \
  --quiet &> /dev/null

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer" \
  --quiet &> /dev/null

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin" \
  --quiet &> /dev/null

print_success "Permissions granted"

print_header "Step 6: Configuring Workload Identity"

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Create workload identity pool
print_info "Creating Workload Identity Pool..."
if gcloud iam workload-identity-pools describe github-actions-pool --location=global &> /dev/null; then
    print_info "Pool already exists"
else
    gcloud iam workload-identity-pools create "github-actions-pool" \
      --project="${PROJECT_ID}" \
      --location="global" \
      --display-name="GitHub Actions Pool"
    print_success "Pool created"
fi

# Create provider
print_info "Creating GitHub provider..."
if gcloud iam workload-identity-pools providers describe github-provider \
  --workload-identity-pool=github-actions-pool --location=global &> /dev/null; then
    print_info "Provider already exists"
else
    gcloud iam workload-identity-pools providers create-oidc "github-provider" \
      --project="${PROJECT_ID}" \
      --location="global" \
      --workload-identity-pool="github-actions-pool" \
      --display-name="GitHub Provider" \
      --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
      --issuer-uri="https://token.actions.githubusercontent.com"
    print_success "Provider created"
fi

# Grant impersonation
print_info "Granting GitHub impersonation rights..."
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/${GITHUB_REPO}" \
  --quiet &> /dev/null

print_success "Workload Identity configured"

# Grant GKE access to Artifact Registry
print_info "Granting GKE access to Artifact Registry..."
GKE_SA=$(gcloud iam service-accounts list \
  --filter="displayName:Compute Engine default service account" \
  --format="value(email)")

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${GKE_SA}" \
  --role="roles/artifactregistry.reader" \
  --quiet &> /dev/null

print_success "GKE can pull images from Artifact Registry"

print_header "Step 7: Updating Repository Files"

# Update Kubernetes deployments
print_info "Updating Kubernetes deployment files..."

if [ -f "k8s-specifications/vote-deployment.yaml" ]; then
    sed -i.bak "s/PROJECT_ID/$PROJECT_ID/g" k8s-specifications/vote-deployment.yaml
    sed -i.bak "s/PROJECT_ID/$PROJECT_ID/g" k8s-specifications/result-deployment.yaml
    sed -i.bak "s/PROJECT_ID/$PROJECT_ID/g" k8s-specifications/worker-deployment.yaml
    rm -f k8s-specifications/*.bak
    print_success "Kubernetes files updated"
else
    print_warning "Kubernetes files not found - make sure you're in the repo root"
fi

# Update workflow files
print_info "Updating GitHub Actions workflows..."
WORKLOAD_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider"

if [ -f ".github/workflows/call-gke-build-vote.yaml" ]; then
    for file in .github/workflows/call-gke-build-*.yaml; do
        # Update workload identity provider
        sed -i.bak "s|workload_identity_provider:.*|workload_identity_provider: '${WORKLOAD_PROVIDER}'|g" "$file"
        # Update service account
        sed -i.bak "s|service_account:.*|service_account: '${SA_EMAIL}'|g" "$file"
    done
    rm -f .github/workflows/*.bak
    print_success "Workflow files updated"
else
    print_warning "Workflow files not found - make sure you're in the repo root"
fi

print_header "Setup Complete!"

# Save configuration
cat > gke-config.txt << EOF
GKE Configuration
==================
Project ID: $PROJECT_ID
Project Number: $PROJECT_NUMBER
Cluster Name: dadismad-cluster-1
Cluster Location: ${CLUSTER_ZONE}${CLUSTER_REGION}
Service Account: $SA_EMAIL
Workload Identity Provider: $WORKLOAD_PROVIDER
GitHub Repository: $GITHUB_REPO
Artifact Registry: us-central1-docker.pkg.dev/$PROJECT_ID/dadismad

Artifact Registry URL: us-central1-docker.pkg.dev/$PROJECT_ID/dadismad
EOF

print_success "Configuration saved to gke-config.txt"

echo ""
print_header "Next Steps"

echo "1. Add GitHub Secrets (Settings → Secrets → Actions):"
echo "   - Name: GKE_PROJECT"
echo "     Value: $PROJECT_ID"
echo ""
echo "   - Name: SECURE_API_TOKEN"
echo "     Value: [Your Sysdig token - or remove scanning steps]"
echo ""
echo "   - Name: SYSDIG_SECURE_URL"
echo "     Value: https://us2.app.sysdig.com"
echo ""

echo "2. Commit and push changes:"
echo "   git add k8s-specifications/ .github/workflows/"
echo "   git commit -m 'Configure GKE with project-specific values'"
echo "   git push origin main"
echo ""

echo "3. Watch deployment:"
echo "   https://github.com/$GITHUB_REPO/actions"
echo ""

echo "4. Check cluster status:"
echo "   kubectl get pods"
echo "   kubectl get services"
echo ""

print_success "All done! See SETUP_GKE_CONNECTION.md for detailed instructions."

# Test cluster connection
print_info "Testing cluster connection..."
if kubectl get nodes &> /dev/null; then
    echo ""
    kubectl get nodes
    echo ""
    print_success "Cluster is ready!"
else
    print_error "Could not connect to cluster"
fi
