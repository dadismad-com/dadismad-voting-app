#!/bin/bash

# GKE Setup Script - UNIFIED VERSION
# One script to rule them all - handles new AND existing projects with progress indicator

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# Progress tracking
TOTAL_STEPS=7
CURRENT_STEP=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}${BOLD}========================================${NC}"
    echo -e "${BLUE}${BOLD}$1${NC}"
    echo -e "${BLUE}${BOLD}========================================${NC}\n"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }

print_step() {
    CURRENT_STEP=$1
    local step_name=$2
    echo -e "\n${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}${BOLD}  Step $CURRENT_STEP/$TOTAL_STEPS: $step_name${NC}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

show_progress() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}Progress: [${NC}"
    printf "%${completed}s" | tr ' ' '='
    printf "%${remaining}s" | tr ' ' '.'
    printf "${CYAN}] ${BOLD}%3d%%${NC}" $percentage
    
    local steps_done=$((current))
    local steps_left=$((total - current))
    printf " ${GREEN}●${NC}%.0s" $(seq 1 $steps_done)
    printf " ${BLUE}○${NC}%.0s" $(seq 1 $steps_left)
    echo ""
}

print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║         🚀 GKE Setup for Voting App 🚀                   ║"
    echo "║                                                           ║"
    echo "║   Automated Google Cloud + GitHub Actions Deployment     ║"
    echo "║   Supports both NEW and EXISTING projects                ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

estimate_time() {
    local step=$1
    case $step in
        1) echo "~1 min" ;;
        2) echo "~2 min" ;;
        3) echo "~1 min" ;;
        4) echo "~5-8 min (longest step)" ;;
        5) echo "~1 min" ;;
        6) echo "~2 min" ;;
        7) echo "~30 sec" ;;
    esac
}

# Check prerequisites
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    echo "Install from: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

print_banner

echo -e "${BLUE}This script will set up Google Cloud for automated deployments${NC}"
echo -e "${BLUE}Works with both new and existing projects${NC}\n"

# Show initial progress
show_progress 0 $TOTAL_STEPS
echo ""

# Ask: new or existing project?
echo -e "${YELLOW}${BOLD}Choose project type:${NC}"
echo "  1) Use an EXISTING Google Cloud project"
echo "  2) Create a NEW Google Cloud project"
echo ""
read -p "Your choice (1 or 2): " PROJECT_CHOICE

if [ "$PROJECT_CHOICE" = "1" ]; then
    # EXISTING PROJECT PATH
    print_info "You chose: Use existing project"
    echo ""
    echo -e "${YELLOW}${BOLD}Your Available Projects:${NC}\n"
    gcloud projects list --format="table(projectId,name,projectNumber)" --limit=20
    echo ""
    read -p "Enter your EXISTING project ID: " PROJECT_ID
    
    if [ -z "$PROJECT_ID" ]; then
        print_error "Project ID is required"
        exit 1
    fi
    
    if ! gcloud projects describe $PROJECT_ID &> /dev/null; then
        print_error "Project '$PROJECT_ID' not found"
        exit 1
    fi
    
    print_success "Using existing project: $PROJECT_ID"
    PROJECT_IS_NEW=false
    
else
    # NEW PROJECT PATH
    print_info "You chose: Create new project"
    echo ""
    read -p "Enter new project ID (or press Enter to auto-generate): " PROJECT_ID
    
    if [ -z "$PROJECT_ID" ]; then
        PROJECT_ID="dadismad-voting-$(date +%s)"
        print_info "Generated project ID: $PROJECT_ID"
    else
        print_info "Using project ID: $PROJECT_ID"
    fi
    PROJECT_IS_NEW=true
fi

# Get billing account
NEEDS_BILLING=false
if [ "$PROJECT_IS_NEW" = true ]; then
    NEEDS_BILLING=true
else
    # Check billing status with visual feedback
    echo ""
    print_info "Checking billing status (this may take 5-10 seconds)..."
    printf "${CYAN}   Waiting for response"
    
    # Run check in background with timeout
    if timeout 15s gcloud beta billing projects describe $PROJECT_ID &> /dev/null 2>&1; then
        printf "\r${CYAN}   ✓ Billing already configured!                ${NC}\n"
        NEEDS_BILLING=false
    else
        printf "\r${CYAN}   ⚠ Billing needs to be configured             ${NC}\n"
        NEEDS_BILLING=true
    fi
fi

if [ "$NEEDS_BILLING" = true ]; then
    echo ""
    read -p "Enter billing account ID (from console.cloud.google.com/billing): " BILLING_ACCOUNT
    if [ -z "$BILLING_ACCOUNT" ]; then
        print_error "Billing account is required"
        exit 1
    fi
fi

# Get GitHub repo
echo ""
read -p "GitHub repository (e.g., dadismad-com/dadismad-voting-app): " GITHUB_REPO
if [ -z "$GITHUB_REPO" ]; then
    print_error "GitHub repository is required"
    exit 1
fi

# Cluster type
echo ""
read -p "Cluster type - (1) Development (~$100/mo) or (2) Production (~$300/mo): " CLUSTER_TYPE
if [ "$CLUSTER_TYPE" = "1" ]; then
    CLUSTER_ZONE="us-central1-a"
    CLUSTER_REGION=""
    IS_REGIONAL=false
    print_info "Will use zonal development cluster"
else
    CLUSTER_ZONE=""
    CLUSTER_REGION="us-central1"
    IS_REGIONAL=true
    print_info "Will use regional production cluster"
fi

# Confirmation
echo ""
print_warning "This will create resources that incur costs (~$100-300/month)"
read -p "Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    print_info "Setup cancelled"
    exit 0
fi

echo ""
show_progress 0 $TOTAL_STEPS
echo ""

# STEP 1: Project Setup
print_step 1 "Setting Up Project"
show_progress 1 $TOTAL_STEPS
echo -e "Estimated time: ${YELLOW}$(estimate_time 1)${NC}\n"

if [ "$PROJECT_IS_NEW" = true ]; then
    if gcloud projects describe $PROJECT_ID &> /dev/null; then
        print_info "Project already exists: $PROJECT_ID"
    else
        print_info "Creating new project: $PROJECT_ID"
        gcloud projects create $PROJECT_ID --name="Voting App"
        print_success "Project created"
    fi
fi

gcloud config set project $PROJECT_ID >/dev/null 2>&1
print_success "Active project set to: $PROJECT_ID"

# Link billing if needed (we already checked earlier)
if [ "$NEEDS_BILLING" = true ]; then
    print_info "Linking billing account..."
    gcloud beta billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT 2>&1 | grep -v "WARNING" || true
    print_success "Billing linked"
else
    print_info "Billing already configured ✓"
fi

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
print_info "Project Number: $PROJECT_NUMBER"

# STEP 2: Enable APIs
print_step 2 "Enabling APIs"
show_progress 2 $TOTAL_STEPS
echo -e "Estimated time: ${YELLOW}$(estimate_time 2)${NC}\n"

print_info "Enabling required APIs (idempotent)..."
gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  compute.googleapis.com \
  --quiet

print_success "APIs enabled"

# STEP 3: Artifact Registry
print_step 3 "Configuring Artifact Registry"
show_progress 3 $TOTAL_STEPS
echo -e "Estimated time: ${YELLOW}$(estimate_time 3)${NC}\n"

if gcloud artifacts repositories describe dadismad --location=us-central1 &> /dev/null 2>&1; then
    print_info "Artifact Registry 'dadismad' already exists ✓"
    print_success "Reusing existing registry"
else
    print_info "Creating Artifact Registry..."
    gcloud artifacts repositories create dadismad \
      --repository-format=docker \
      --location=us-central1 \
      --description="Voting app Docker images"
    print_success "Artifact Registry created"
fi

# STEP 4: GKE Cluster
print_step 4 "Configuring GKE Cluster"
show_progress 4 $TOTAL_STEPS
echo -e "Estimated time: ${YELLOW}$(estimate_time 4)${NC}\n"

CLUSTER_EXISTS=false

# Check for existing cluster
if [ "$IS_REGIONAL" = true ]; then
    if gcloud container clusters describe dadismad-cluster-1 --region=$CLUSTER_REGION &> /dev/null 2>&1; then
        print_info "Regional cluster already exists ✓"
        CLUSTER_EXISTS=true
    fi
else
    if gcloud container clusters describe dadismad-cluster-1 --zone=$CLUSTER_ZONE &> /dev/null 2>&1; then
        print_info "Zonal cluster already exists ✓"
        CLUSTER_EXISTS=true
    fi
fi

if [ "$CLUSTER_EXISTS" = true ]; then
    print_success "Reusing existing cluster"
else
    print_warning "This is the longest step - grab a coffee! ☕"
    
    if [ "$IS_REGIONAL" = true ]; then
        print_info "Creating regional GKE cluster..."
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
        print_info "Creating zonal GKE cluster..."
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

# STEP 5: Service Account
print_step 5 "Configuring Service Account"
show_progress 5 $TOTAL_STEPS
echo -e "Estimated time: ${YELLOW}$(estimate_time 5)${NC}\n"

SA_NAME="dadismad-github-actions"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe $SA_EMAIL &> /dev/null 2>&1; then
    print_info "Service account already exists ✓"
    print_success "Reusing existing service account"
else
    print_info "Creating service account..."
    gcloud iam service-accounts create $SA_NAME \
      --display-name="GitHub Actions Deployment SA" \
      --description="Automated deployments from GitHub Actions"
    print_success "Service account created"
fi

print_info "Granting permissions (idempotent)..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.developer" \
  --quiet &> /dev/null || true

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/artifactregistry.writer" \
  --quiet &> /dev/null || true

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin" \
  --quiet &> /dev/null || true

print_success "Permissions configured"

# STEP 6: Workload Identity
print_step 6 "Configuring Workload Identity"
show_progress 6 $TOTAL_STEPS
echo -e "Estimated time: ${YELLOW}$(estimate_time 6)${NC}\n"

if gcloud iam workload-identity-pools describe github-actions-pool --location=global &> /dev/null 2>&1; then
    print_info "Workload Identity Pool already exists ✓"
else
    print_info "Creating Workload Identity Pool..."
    gcloud iam workload-identity-pools create "github-actions-pool" \
      --project="${PROJECT_ID}" \
      --location="global" \
      --display-name="GitHub Actions Pool"
    print_success "Pool created"
fi

if gcloud iam workload-identity-pools providers describe github-provider \
  --workload-identity-pool=github-actions-pool --location=global &> /dev/null 2>&1; then
    print_info "GitHub provider already exists ✓"
else
    print_info "Creating GitHub provider..."
    gcloud iam workload-identity-pools providers create-oidc "github-provider" \
      --project="${PROJECT_ID}" \
      --location="global" \
      --workload-identity-pool="github-actions-pool" \
      --display-name="GitHub Provider" \
      --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
      --attribute-condition="assertion.repository_owner=='${GITHUB_REPO%%/*}'" \
      --issuer-uri="https://token.actions.githubusercontent.com"
    print_success "Provider created"
fi

print_info "Granting GitHub impersonation rights..."
gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/${GITHUB_REPO}" \
  --quiet &> /dev/null || true

print_success "Workload Identity configured"

print_info "Granting GKE access to Artifact Registry..."
GKE_SA=$(gcloud iam service-accounts list \
  --filter="displayName:Compute Engine default service account" \
  --format="value(email)")

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${GKE_SA}" \
  --role="roles/artifactregistry.reader" \
  --quiet &> /dev/null || true

print_success "GKE configured"

# STEP 7: Update Repository Files
print_step 7 "Updating Repository Files"
show_progress 7 $TOTAL_STEPS
echo -e "Estimated time: ${YELLOW}$(estimate_time 7)${NC}\n"

print_info "Updating Kubernetes deployments..."
if [ -f "k8s-specifications/vote-deployment.yaml" ]; then
    sed -i.bak "s/PROJECT_ID/$PROJECT_ID/g" k8s-specifications/vote-deployment.yaml
    sed -i.bak "s/PROJECT_ID/$PROJECT_ID/g" k8s-specifications/result-deployment.yaml
    sed -i.bak "s/PROJECT_ID/$PROJECT_ID/g" k8s-specifications/worker-deployment.yaml
    rm -f k8s-specifications/*.bak
    print_success "Kubernetes files updated"
else
    print_warning "Kubernetes files not found - check directory"
fi

WORKLOAD_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider"

print_info "Updating GitHub Actions workflows..."
if [ -f ".github/workflows/call-gke-build-vote.yaml" ]; then
    for file in .github/workflows/call-gke-build-*.yaml; do
        sed -i.bak "s|workload_identity_provider:.*|workload_identity_provider: '${WORKLOAD_PROVIDER}'|g" "$file"
        sed -i.bak "s|service_account:.*|service_account: '${SA_EMAIL}'|g" "$file"
    done
    rm -f .github/workflows/*.bak
    print_success "Workflow files updated"
else
    print_warning "Workflow files not found - check directory"
fi

# Final progress
show_progress $TOTAL_STEPS $TOTAL_STEPS
echo ""

# Save configuration
cat > gke-config.txt << EOF
GKE Configuration
==================
Setup Type: $([ "$PROJECT_IS_NEW" = true ] && echo "New Project" || echo "Existing Project")
Project ID: $PROJECT_ID
Project Number: $PROJECT_NUMBER
Cluster Name: dadismad-cluster-1
Cluster Type: $([ "$IS_REGIONAL" = true ] && echo "Regional (${CLUSTER_REGION})" || echo "Zonal (${CLUSTER_ZONE})")
Service Account: $SA_EMAIL
Workload Identity Provider: $WORKLOAD_PROVIDER
GitHub Repository: $GITHUB_REPO
Artifact Registry: us-central1-docker.pkg.dev/$PROJECT_ID/dadismad

Setup completed: $(date)
EOF

print_success "Configuration saved to gke-config.txt"

print_header "🎉 Setup Complete! 🎉"

# Display next steps
echo -e "${CYAN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║                    NEXT STEPS                             ║${NC}"
echo -e "${CYAN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}${BOLD}1. Add GitHub Secrets${NC} (Settings → Secrets → Actions):"
echo -e "   ${GREEN}├─${NC} Name: ${BOLD}GKE_PROJECT${NC}"
echo -e "   ${GREEN}│  ${NC}Value: ${CYAN}$PROJECT_ID${NC}"
echo ""
echo -e "   ${GREEN}├─${NC} Name: ${BOLD}SECURE_API_TOKEN${NC}"
echo -e "   ${GREEN}│  ${NC}Value: [Your Sysdig token - or skip scanning]"
echo ""
echo -e "   ${GREEN}└─${NC} Name: ${BOLD}SYSDIG_SECURE_URL${NC}"
echo -e "      Value: ${CYAN}https://us2.app.sysdig.com${NC}"
echo ""

echo -e "${YELLOW}${BOLD}2. Commit and push changes:${NC}"
echo -e "   ${BLUE}git add k8s-specifications/ .github/workflows/ gke-config.txt${NC}"
echo -e "   ${BLUE}git commit -m 'Configure GKE deployment'${NC}"
echo -e "   ${BLUE}git push origin main${NC}"
echo ""

echo -e "${YELLOW}${BOLD}3. Watch deployment:${NC}"
echo -e "   ${CYAN}https://github.com/$GITHUB_REPO/actions${NC}"
echo ""

echo -e "${YELLOW}${BOLD}4. Check cluster status:${NC}"
print_info "Testing cluster connection..."
echo ""
kubectl get nodes
echo ""
print_success "Cluster is ready!"

echo ""
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  All done! See SETUP_GKE_CONNECTION.md for more help      ${NC}"
echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}\n"
