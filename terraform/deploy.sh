#!/bin/bash

# Script de déploiement pour Black Friday Survival - Infrastructure AWS EKS (Production)
# Usage: ./deploy.sh [plan|apply|destroy]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ACTION=${1:-plan}
ENVIRONMENT="prod"

# Validate action
if [[ "$ACTION" != "plan" && "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
    print_error "Invalid action. Use 'plan', 'apply', or 'destroy'"
    echo "Usage: $0 [plan|apply|destroy]"
    exit 1
fi

print_info "Environment: $ENVIRONMENT (Production)"
print_info "Action: $ACTION"

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed!"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed!"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_warning "kubectl is not installed. You'll need it to interact with the cluster."
fi

# Check AWS credentials
print_info "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured!"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
print_info "AWS Account: $AWS_ACCOUNT"

# Navigate to terraform directory
cd "$(dirname "$0")"

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    print_info "Initializing Terraform..."
    terraform init
fi

# Execute action
case $ACTION in
    plan)
        print_info "Planning infrastructure for Production..."
        terraform plan -out=tfplan
        print_info "Plan saved to tfplan. Review and run with: $0 apply"
        ;;

    apply)
        if [ ! -f "tfplan" ]; then
            print_warning "No plan file found. Creating plan first..."
            terraform plan -out=tfplan
        fi

        print_warning "About to apply infrastructure changes for PRODUCTION..."
        read -p "Are you sure? (yes/no): " confirm

        if [ "$confirm" == "yes" ]; then
            print_info "Applying infrastructure..."
            terraform apply tfplan
            rm -f tfplan

            print_info "Infrastructure deployed successfully!"

            # Get cluster name and configure kubectl
            CLUSTER_NAME=$(terraform output -raw cluster_name)
            AWS_REGION=$(terraform output -raw aws_region || echo "eu-south-2")

            print_info "Configuring kubectl..."
            aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

            print_info "Verifying cluster connection..."
            kubectl get nodes

            print_info "=== Next Steps ==="
            echo "1. Deploy Cluster Autoscaler: kubectl apply -f ../kubernetes-manifests/cluster-autoscaler.yaml"
            echo "2. Install AWS Load Balancer Controller (see DEPLOYMENT.md)"
            echo "3. Deploy applications: kubectl apply -f ../kubernetes-manifests/"
            echo "4. View CloudWatch Dashboard: $(terraform output -raw cloudwatch_dashboard_name)"
        else
            print_info "Apply cancelled."
        fi
        ;;

    destroy)
        print_error "WARNING: This will destroy all PRODUCTION infrastructure!"
        read -p "Type 'destroy-prod' to confirm: " confirm

        if [ "$confirm" == "destroy-prod" ]; then
            print_info "Destroying infrastructure..."
            terraform destroy
            print_info "Infrastructure destroyed."
        else
            print_info "Destroy cancelled."
        fi
        ;;
esac

