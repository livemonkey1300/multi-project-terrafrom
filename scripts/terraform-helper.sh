#!/bin/bash

# Terraform Multi-Directory Helper Script
# This script helps with local development and testing of the Terraform configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ACTION=""
ENVIRONMENT=""
MODULE=""
TERRAFORM_DIR="terraform"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Terraform Multi-Directory Helper Script

Usage: $0 [OPTIONS]

OPTIONS:
    -a, --action        Action to perform (format|validate|plan|apply|destroy)
    -e, --environment   Environment (dev|staging|all)
    -m, --module        Module (network|app|all)
    -h, --help          Show this help message

EXAMPLES:
    # Format all Terraform files
    $0 -a format

    # Validate all configurations
    $0 -a validate

    # Plan for dev environment, all modules
    $0 -a plan -e dev -m all

    # Plan for staging environment, network module only
    $0 -a plan -e staging -m network

    # Apply dev environment (interactive)
    $0 -a apply -e dev -m all

NOTES:
    - This script assumes you have Terraform installed and configured
    - For apply/destroy operations, you'll be prompted for confirmation
    - Make sure your AWS credentials are configured (aws configure or env vars)
    - S3 backend must be properly configured in the Terraform files

EOF
}

# Function to validate inputs
validate_inputs() {
    case $ACTION in
        format|validate)
            # These actions don't require environment/module
            ;;
        plan|apply|destroy)
            if [[ -z "$ENVIRONMENT" || -z "$MODULE" ]]; then
                print_error "Environment and module are required for $ACTION action"
                exit 1
            fi
            if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|all)$ ]]; then
                print_error "Environment must be one of: dev, staging, all"
                exit 1
            fi
            if [[ ! "$MODULE" =~ ^(network|app|all)$ ]]; then
                print_error "Module must be one of: network, app, all"
                exit 1
            fi
            ;;
        *)
            print_error "Invalid action: $ACTION"
            show_usage
            exit 1
            ;;
    esac
}

# Function to get directories based on environment and module selection
get_directories() {
    local dirs=()
    
    if [[ "$ENVIRONMENT" == "all" ]]; then
        environments=("dev" "staging")
    else
        environments=("$ENVIRONMENT")
    fi
    
    if [[ "$MODULE" == "all" ]]; then
        modules=("network" "app")
    else
        modules=("$MODULE")
    fi
    
    for env in "${environments[@]}"; do
        for mod in "${modules[@]}"; do
            dir="$TERRAFORM_DIR/environments/$env/$mod"
            if [[ -d "$dir" ]]; then
                dirs+=("$dir")
            else
                print_warning "Directory does not exist: $dir"
            fi
        done
    done
    
    echo "${dirs[@]}"
}

# Function to format Terraform files
terraform_format() {
    print_status "Running Terraform format check..."
    if terraform fmt -check -recursive "$TERRAFORM_DIR/"; then
        print_success "All files are properly formatted"
    else
        print_warning "Some files need formatting. Run 'terraform fmt -recursive $TERRAFORM_DIR/' to fix"
        return 1
    fi
}

# Function to validate Terraform configurations
terraform_validate() {
    print_status "Validating Terraform configurations..."
    local dirs=($(find "$TERRAFORM_DIR/environments" -name "*.tf" -exec dirname {} \; | sort -u))
    
    for dir in "${dirs[@]}"; do
        print_status "Validating $dir"
        cd "$dir"
        terraform init -backend=false > /dev/null 2>&1
        if terraform validate; then
            print_success "Validation passed for $dir"
        else
            print_error "Validation failed for $dir"
            cd - > /dev/null
            return 1
        fi
        cd - > /dev/null
    done
    
    print_success "All configurations are valid"
}

# Function to run terraform plan
terraform_plan() {
    local dirs=($(get_directories))
    
    if [[ ${#dirs[@]} -eq 0 ]]; then
        print_error "No directories found for the specified environment and module"
        return 1
    fi
    
    for dir in "${dirs[@]}"; do
        print_status "Planning $dir"
        cd "$dir"
        
        # Initialize if needed
        if [[ ! -d ".terraform" ]]; then
            print_status "Initializing Terraform for $dir"
            terraform init
        fi
        
        # Extract environment and module from path
        local env=$(echo "$dir" | cut -d'/' -f3)
        local mod=$(echo "$dir" | cut -d'/' -f4)
        
        # Run plan
        terraform plan \
            -var-file="../../../terraform.tfvars" \
            -var="environment=$env" \
            -out="tfplan-$env-$mod"
        
        print_success "Plan completed for $dir"
        cd - > /dev/null
    done
}

# Function to run terraform apply
terraform_apply() {
    local dirs=($(get_directories))
    
    if [[ ${#dirs[@]} -eq 0 ]]; then
        print_error "No directories found for the specified environment and module"
        return 1
    fi
    
    print_warning "You are about to apply Terraform changes to:"
    for dir in "${dirs[@]}"; do
        echo "  - $dir"
    done
    
    read -p "Are you sure you want to continue? (yes/no): " confirmation
    if [[ "$confirmation" != "yes" ]]; then
        print_status "Apply cancelled by user"
        return 0
    fi
    
    for dir in "${dirs[@]}"; do
        print_status "Applying $dir"
        cd "$dir"
        
        # Extract environment and module from path
        local env=$(echo "$dir" | cut -d'/' -f3)
        local mod=$(echo "$dir" | cut -d'/' -f4)
        local plan_file="tfplan-$env-$mod"
        
        if [[ -f "$plan_file" ]]; then
            terraform apply "$plan_file"
            print_success "Apply completed for $dir"
        else
            print_error "Plan file not found: $plan_file. Run plan first."
            cd - > /dev/null
            return 1
        fi
        
        cd - > /dev/null
    done
}

# Function to run terraform destroy
terraform_destroy() {
    local dirs=($(get_directories))
    
    if [[ ${#dirs[@]} -eq 0 ]]; then
        print_error "No directories found for the specified environment and module"
        return 1
    fi
    
    print_error "WARNING: You are about to DESTROY infrastructure in:"
    for dir in "${dirs[@]}"; do
        echo "  - $dir"
    done
    
    read -p "Type 'destroy' to confirm: " confirmation
    if [[ "$confirmation" != "destroy" ]]; then
        print_status "Destroy cancelled by user"
        return 0
    fi
    
    # Reverse order for destroy (app before network)
    local reversed_dirs=()
    for ((i=${#dirs[@]}-1; i>=0; i--)); do
        reversed_dirs+=("${dirs[i]}")
    done
    
    for dir in "${reversed_dirs[@]}"; do
        print_status "Destroying $dir"
        cd "$dir"
        
        # Extract environment from path
        local env=$(echo "$dir" | cut -d'/' -f3)
        
        terraform plan -destroy \
            -var-file="../../../terraform.tfvars" \
            -var="environment=$env" \
            -out="destroy-plan"
        
        terraform apply "destroy-plan"
        print_success "Destroy completed for $dir"
        cd - > /dev/null
    done
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -m|--module)
            MODULE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Check if action is provided
if [[ -z "$ACTION" ]]; then
    print_error "Action is required"
    show_usage
    exit 1
fi

# Validate inputs
validate_inputs

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed or not in PATH"
    exit 1
fi

# Check if we're in the right directory
if [[ ! -d "$TERRAFORM_DIR" ]]; then
    print_error "Terraform directory not found: $TERRAFORM_DIR"
    print_error "Make sure you're running this script from the repository root"
    exit 1
fi

# Execute the requested action
case $ACTION in
    format)
        terraform_format
        ;;
    validate)
        terraform_validate
        ;;
    plan)
        terraform_plan
        ;;
    apply)
        terraform_apply
        ;;
    destroy)
        terraform_destroy
        ;;
esac

print_success "Action '$ACTION' completed successfully"