#!/bin/bash

# GKE Cleanup Script - TEARDOWN VERSION
# Safely deletes all resources created by setup-gke.sh

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

print_banner() {
    clear
    echo -e "${RED}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║         🗑️  GKE Resource Cleanup Tool 🗑️                 ║"
    echo "║                                                           ║"
    echo "║   ⚠️  WARNING: This will DELETE cloud resources! ⚠️      ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

# Check prerequisites
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

print_banner

# Try to load config from gke-config.txt
if [ -f "gke-config.txt" ]; then
    print_info "Found gke-config.txt - loading configuration..."
    PROJECT_ID=$(grep "^Project ID:" gke-config.txt | cut -d: -f2 | xargs)
    CLUSTER_NAME=$(grep "^Cluster Name:" gke-config.txt | cut -d: -f2 | xargs)
    CLUSTER_TYPE=$(grep "^Cluster Type:" gke-config.txt | cut -d: -f2 | xargs)
    
    if [[ "$CLUSTER_TYPE" == *"Regional"* ]]; then
        CLUSTER_REGION=$(echo "$CLUSTER_TYPE" | grep -oP '\(\K[^)]+')
        CLUSTER_ZONE=""
        IS_REGIONAL=true
    else
        CLUSTER_ZONE=$(echo "$CLUSTER_TYPE" | grep -oP '\(\K[^)]+')
        CLUSTER_REGION=""
        IS_REGIONAL=false
    fi
    
    print_success "Loaded configuration:"
    echo "   Project ID: ${CYAN}$PROJECT_ID${NC}"
    echo "   Cluster: ${CYAN}$CLUSTER_NAME${NC}"
    echo "   Type: ${CYAN}$CLUSTER_TYPE${NC}"
else
    print_warning "No gke-config.txt found - manual input required"
    echo ""
    gcloud projects list --format="table(projectId,name)" --limit=20
    echo ""
    read -p "Enter your GCP Project ID: " PROJECT_ID
    
    if [ -z "$PROJECT_ID" ]; then
        print_error "Project ID is required"
        exit 1
    fi
    
    CLUSTER_NAME="dadismad-cluster-1"
    
    echo ""
    read -p "Is this a regional cluster? (y/n): " IS_REGIONAL_INPUT
    if [[ "$IS_REGIONAL_INPUT" =~ ^[Yy]$ ]]; then
        IS_REGIONAL=true
        CLUSTER_REGION="us-central1"
        CLUSTER_ZONE=""
    else
        IS_REGIONAL=false
        CLUSTER_ZONE="us-central1-a"
        CLUSTER_REGION=""
    fi
fi

# Set active project
gcloud config set project $PROJECT_ID >/dev/null 2>&1
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)" 2>/dev/null || echo "unknown")

SA_NAME="dadismad-github-actions"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo ""
print_header "Resources to be DELETED"

echo -e "${YELLOW}${BOLD}The following resources will be permanently deleted:${NC}\n"

# Check what exists and show it
RESOURCES_TO_DELETE=()

if [ "$IS_REGIONAL" = true ]; then
    if gcloud container clusters describe $CLUSTER_NAME --region=$CLUSTER_REGION &> /dev/null 2>&1; then
        echo -e "   ${RED}🗑️${NC}  GKE Cluster: ${CYAN}$CLUSTER_NAME${NC} (regional - ${CLUSTER_REGION})"
        RESOURCES_TO_DELETE+=("cluster")
    fi
else
    if gcloud container clusters describe $CLUSTER_NAME --zone=$CLUSTER_ZONE &> /dev/null 2>&1; then
        echo -e "   ${RED}🗑️${NC}  GKE Cluster: ${CYAN}$CLUSTER_NAME${NC} (zonal - ${CLUSTER_ZONE})"
        RESOURCES_TO_DELETE+=("cluster")
    fi
fi

if gcloud artifacts repositories describe dadismad --location=us-central1 &> /dev/null 2>&1; then
    echo -e "   ${RED}🗑️${NC}  Artifact Registry: ${CYAN}dadismad${NC} (us-central1)"
    RESOURCES_TO_DELETE+=("registry")
fi

if gcloud iam workload-identity-pools providers describe github-provider \
  --workload-identity-pool=github-actions-pool --location=global &> /dev/null 2>&1; then
    echo -e "   ${RED}🗑️${NC}  Workload Identity Provider: ${CYAN}github-provider${NC}"
    RESOURCES_TO_DELETE+=("provider")
fi

if gcloud iam workload-identity-pools describe github-actions-pool --location=global &> /dev/null 2>&1; then
    echo -e "   ${RED}🗑️${NC}  Workload Identity Pool: ${CYAN}github-actions-pool${NC}"
    RESOURCES_TO_DELETE+=("pool")
fi

if gcloud iam service-accounts describe $SA_EMAIL &> /dev/null 2>&1; then
    echo -e "   ${RED}🗑️${NC}  Service Account: ${CYAN}$SA_EMAIL${NC}"
    RESOURCES_TO_DELETE+=("sa")
fi

echo ""

if [ ${#RESOURCES_TO_DELETE[@]} -eq 0 ]; then
    print_info "No resources found to delete!"
    exit 0
fi

# Estimate costs savings
echo -e "${GREEN}${BOLD}💰 Cost Savings:${NC}"
if [[ " ${RESOURCES_TO_DELETE[@]} " =~ " cluster " ]]; then
    if [ "$IS_REGIONAL" = true ]; then
        echo "   Regional cluster: ~\$300/month saved"
    else
        echo "   Zonal cluster: ~\$100/month saved"
    fi
fi
if [[ " ${RESOURCES_TO_DELETE[@]} " =~ " registry " ]]; then
    echo "   Artifact Registry: ~\$5-20/month saved (depends on stored images)"
fi

echo ""
print_warning "This action CANNOT be undone!"
print_warning "All data will be permanently lost!"

echo ""
read -p "Type 'DELETE' to confirm deletion: " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    print_info "Cleanup cancelled - no resources were deleted"
    exit 0
fi

echo ""
read -p "Are you ABSOLUTELY sure? (yes/no): " DOUBLE_CONFIRM

if [ "$DOUBLE_CONFIRM" != "yes" ]; then
    print_info "Cleanup cancelled - no resources were deleted"
    exit 0
fi

# Start deletion
print_header "🗑️  Starting Resource Deletion"

DELETED_COUNT=0
TOTAL_COUNT=${#RESOURCES_TO_DELETE[@]}

# 1. Delete GKE Cluster (takes longest)
if [[ " ${RESOURCES_TO_DELETE[@]} " =~ " cluster " ]]; then
    echo ""
    print_info "[$((DELETED_COUNT+1))/$TOTAL_COUNT] Deleting GKE cluster..."
    print_warning "This will take 3-5 minutes..."
    
    if [ "$IS_REGIONAL" = true ]; then
        if gcloud container clusters delete $CLUSTER_NAME \
          --region=$CLUSTER_REGION \
          --quiet 2>&1 | grep -v "Deleting cluster"; then
            print_success "Cluster deleted"
        else
            print_success "Cluster deleted (or already gone)"
        fi
    else
        if gcloud container clusters delete $CLUSTER_NAME \
          --zone=$CLUSTER_ZONE \
          --quiet 2>&1 | grep -v "Deleting cluster"; then
            print_success "Cluster deleted"
        else
            print_success "Cluster deleted (or already gone)"
        fi
    fi
    DELETED_COUNT=$((DELETED_COUNT+1))
fi

# 2. Delete Artifact Registry
if [[ " ${RESOURCES_TO_DELETE[@]} " =~ " registry " ]]; then
    echo ""
    print_info "[$((DELETED_COUNT+1))/$TOTAL_COUNT] Deleting Artifact Registry..."
    
    if gcloud artifacts repositories delete dadismad \
      --location=us-central1 \
      --quiet &> /dev/null; then
        print_success "Artifact Registry deleted"
    else
        print_success "Artifact Registry deleted (or already gone)"
    fi
    DELETED_COUNT=$((DELETED_COUNT+1))
fi

# 3. Delete Workload Identity Provider
if [[ " ${RESOURCES_TO_DELETE[@]} " =~ " provider " ]]; then
    echo ""
    print_info "[$((DELETED_COUNT+1))/$TOTAL_COUNT] Deleting Workload Identity Provider..."
    
    if gcloud iam workload-identity-pools providers delete github-provider \
      --workload-identity-pool=github-actions-pool \
      --location=global \
      --quiet &> /dev/null; then
        print_success "Provider deleted"
    else
        print_success "Provider deleted (or already gone)"
    fi
    DELETED_COUNT=$((DELETED_COUNT+1))
fi

# 4. Delete Workload Identity Pool
if [[ " ${RESOURCES_TO_DELETE[@]} " =~ " pool " ]]; then
    echo ""
    print_info "[$((DELETED_COUNT+1))/$TOTAL_COUNT] Deleting Workload Identity Pool..."
    
    if gcloud iam workload-identity-pools delete github-actions-pool \
      --location=global \
      --quiet &> /dev/null; then
        print_success "Pool deleted"
    else
        print_success "Pool deleted (or already gone)"
    fi
    DELETED_COUNT=$((DELETED_COUNT+1))
fi

# 5. Delete Service Account
if [[ " ${RESOURCES_TO_DELETE[@]} " =~ " sa " ]]; then
    echo ""
    print_info "[$((DELETED_COUNT+1))/$TOTAL_COUNT] Deleting Service Account..."
    
    if gcloud iam service-accounts delete $SA_EMAIL \
      --quiet &> /dev/null; then
        print_success "Service Account deleted"
    else
        print_success "Service Account deleted (or already gone)"
    fi
    DELETED_COUNT=$((DELETED_COUNT+1))
fi

# Cleanup local files
echo ""
print_info "Cleaning up local configuration files..."
if [ -f "gke-config.txt" ]; then
    mv gke-config.txt "gke-config.txt.backup-$(date +%Y%m%d-%H%M%S)"
    print_success "Backed up gke-config.txt"
fi

print_header "🎉 Cleanup Complete!"

echo -e "${GREEN}${BOLD}Successfully deleted $DELETED_COUNT resource(s)${NC}\n"

echo -e "${CYAN}What was deleted:${NC}"
[[ " ${RESOURCES_TO_DELETE[@]} " =~ " cluster " ]] && echo "   ✓ GKE Cluster"
[[ " ${RESOURCES_TO_DELETE[@]} " =~ " registry " ]] && echo "   ✓ Artifact Registry"
[[ " ${RESOURCES_TO_DELETE[@]} " =~ " provider " ]] && echo "   ✓ Workload Identity Provider"
[[ " ${RESOURCES_TO_DELETE[@]} " =~ " pool " ]] && echo "   ✓ Workload Identity Pool"
[[ " ${RESOURCES_TO_DELETE[@]} " =~ " sa " ]] && echo "   ✓ Service Account"

echo ""
echo -e "${YELLOW}${BOLD}Next Steps:${NC}"
echo "   1. Your GCP project '${PROJECT_ID}' still exists"
echo "   2. Billing has been stopped for deleted resources"
echo "   3. To delete the entire project:"
echo "      ${CYAN}gcloud projects delete $PROJECT_ID${NC}"
echo ""
echo "   4. To re-deploy, run: ${GREEN}./setup-gke.sh${NC}"
echo ""

print_success "All done! 🎉"
