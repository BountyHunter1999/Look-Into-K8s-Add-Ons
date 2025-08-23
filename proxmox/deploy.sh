#!/bin/bash
TF_CMD="docker compose run --rm terraform"

# Function to display usage information
show_usage() {
    echo "Usage: $0 [environment] [operation]"
    echo ""
    echo "Operations:"
    echo "  plan     - Run terraform plan"
    echo "  apply    - Run terraform apply"
    echo "  destroy  - Run terraform destroy"
    echo "  all      - Run plan and apply"
    echo ""
    echo "Examples:"
    echo "  $0 proxmox-k8s plan"
    echo "  $0 proxmox-k8s apply"
    echo "  $0 proxmox-k8s all"
    echo ""
    echo "If no arguments provided, script will prompt for input."
}

terraform_plan() {
    local TERRAFORM_ENV="$1"
    export TERRAFORM_ENV

    echo "Running terraform plan for environment: $TERRAFORM_ENV"
    $TF_CMD init -upgrade
    $TF_CMD plan
}

terraform_apply() {
    local TERRAFORM_ENV="$1"
    export TERRAFORM_ENV

    echo "Running terraform apply for environment: $TERRAFORM_ENV"
    $TF_CMD apply -auto-approve
}

terraform_destroy() {
    local TERRAFORM_ENV="$1"
    export TERRAFORM_ENV

    echo "Running terraform destroy for environment: $TERRAFORM_ENV"
    echo "WARNING: This will destroy all resources!"
    $TF_CMD destroy -auto-approve
}

# Function to get user input
get_user_input() {
    echo "Terraform Deployment Script"
    echo "=========================="
    echo ""
    
    # Get environment
    read -p "Enter environment name (default: proxmox-k8s): " environment
    environment=${environment:-proxmox-k8s}
    
    # Get operation
    echo ""
    echo "Available operations:"
    echo "1) plan"
    echo "2) apply"
    echo "3) destroy"
    echo "4) all (plan + apply)"
    echo ""
    read -p "Select operation (1-4): " operation_choice
    
    case $operation_choice in
        1) operation="plan" ;;
        2) operation="apply" ;;
        3) operation="destroy" ;;
        4) operation="all" ;;
        *) echo "Invalid choice. Exiting."; exit 1 ;;
    esac
}

# Main script logic
if [[ $# -eq 0 ]]; then
    # No arguments provided, get user input
    get_user_input
elif [[ $# -eq 1 && "$1" == "--help" || "$1" == "-h" ]]; then
    show_usage
    exit 0
elif [[ $# -eq 2 ]]; then
    # Arguments provided
    environment="$1"
    operation="$2"
else
    echo "Error: Invalid number of arguments"
    show_usage
    exit 1
fi

echo ""
echo "Environment: $environment"
echo "Operation: $operation"
echo ""

# Execute the selected operation
case $operation in
    plan)
        terraform_plan "$environment"
        ;;
    apply)
        terraform_apply "$environment"
        ;;
    destroy)
        terraform_destroy "$environment"
        ;;
    all)
        terraform_plan "$environment"
        echo ""
        read -p "Plan completed. Continue with apply? (yes/no): " continue_apply
        if [[ $continue_apply == "yes" ]]; then
            terraform_apply "$environment"
        else
            echo "Apply cancelled."
        fi
        ;;
    *)
        echo "Error: Invalid operation '$operation'"
        show_usage
        exit 1
        ;;
esac