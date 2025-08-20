#!/bin/bash

# set -x

red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
bold=$(tput bold)
reset=$(tput sgr0)

# Default values
INSTALL_ARGOCD=false
INSTALL_RANCHER=false

echo "Current directory: $(pwd)"

# Function to display usage
show_usage() {
    echo "${bold}Usage:${reset} $0 [OPTIONS]"
    echo ""
    echo "${bold}Options:${reset}"
    echo "  --argocd     Install ArgoCD"
    echo "  --rancher    Install Rancher"
    echo "  --all        Install both ArgoCD and Rancher"
    echo "  --help       Show this help message"
    echo ""
    echo "${bold}Examples:${reset}"
    echo "  $0 --argocd                    # Install only ArgoCD"
    echo "  $0 --rancher                   # Install only Rancher"
    echo "  $0 --all                       # Install both ArgoCD and Rancher"
    echo "  $0 --argocd --rancher          # Install both ArgoCD and Rancher"
    echo ""
}

# Function to check if namespace exists
namespace_exists() {
    local namespace=$1
    kubectl get namespace "$namespace" >/dev/null 2>&1
}

# Function to check if helm release exists
helm_release_exists() {
    local release=$1
    local namespace=$2
    helm list -n "$namespace" | grep -q "$release"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --argocd)
            INSTALL_ARGOCD=true
            shift
            ;;
        --rancher)
            INSTALL_RANCHER=true
            shift
            ;;
        --all)
            INSTALL_ARGOCD=true
            INSTALL_RANCHER=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "${red}Error: Unknown option $1${reset}"
            show_usage
            exit 1
            ;;
    esac
done

# Check if at least one option is selected
if [[ "$INSTALL_ARGOCD" == false && "$INSTALL_RANCHER" == false ]]; then
    echo "${red}Error: Please specify at least one option (--argocd, --rancher, or --all)${reset}"
    show_usage
    exit 1
fi

echo "${blue}${bold}Installation Summary:${reset}"
if [[ "$INSTALL_ARGOCD" == true ]]; then
    echo "  ✓ ArgoCD will be installed"
fi
if [[ "$INSTALL_RANCHER" == true ]]; then
    echo "  ✓ Rancher will be installed"
fi
echo ""

# Add Helm repositories
echo "${green}Adding Helm repositories...${reset}"

# This is needed regardless
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Check if ingress-nginx is already deployed
if helm_release_exists "ingress-nginx" "ingress-nginx"; then
    echo "${yellow}ingress-nginx is already deployed. Skipping installation.${reset}"
else
    echo "${green}Installing ingress-nginx---------------------------------------------------------------------------${reset}"
    helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace -f setup_system/manifests/values-ingress-nginx.yaml

    echo "${green}Waiting for ingress-nginx to be ready---------------------------------------------------------------------------${reset}"
    kubectl wait --namespace ingress-nginx \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/component=controller \
            --timeout=90s
fi

# Install ArgoCD if selected
if [[ "$INSTALL_ARGOCD" == true ]]; then
    helm repo add argo-cd https://argoproj.github.io/argo-helm
    helm repo update

    # Check if ArgoCD is already deployed
    if helm_release_exists "argo-cd" "argocd"; then
        echo "${yellow}ArgoCD is already deployed. Skipping installation.${reset}"
    else
        echo "${green}Installing argo-cd---------------------------------------------------------------------------${reset}"
        helm upgrade -i argo-cd argo/argo-cd --namespace argocd --create-namespace -f setup_system/manifests/values-argocd-ingress.yaml

        echo "${green}Waiting for argo-cd to be ready---------------------------------------------------------------------------${reset}"
        kubectl wait --namespace argocd \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/name=argocd-server \
            --timeout=90s
    fi
fi

# Install Rancher if selected
if [[ "$INSTALL_RANCHER" == true ]]; then
    helm repo add rancher-latest https://releases.rancher.com/server-charts/latest

    # Add the Jetstack Helm repository
    helm repo add jetstack https://charts.jetstack.io

    # Update Helm repositories
    helm repo update

    # Check if Rancher is already deployed
    if helm_release_exists "rancher" "cattle-system"; then
        echo "${yellow}Rancher is already deployed. Skipping installation.${reset}"
    else
        echo "${green}Installing rancher---------------------------------------------------------------------------${reset}"

        # Check if cert-manager is already deployed
        if helm_release_exists "cert-manager" "cert-manager"; then
            echo "${yellow}cert-manager is already deployed. Skipping installation.${reset}"
        else
            echo "${green}Installing cert-manager...${reset}"

            # Install the cert-manager CRDs
            kubectl create namespace cert-manager
            # kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml --namespace cert-manager

            # Install the cert-manager Helm chart
            helm install cert-manager jetstack/cert-manager \
                --namespace cert-manager \
                --create-namespace \
                --set installCRDs=true

            echo "${green}Waiting for cert-manager to be ready...${reset}"
            kubectl wait --namespace cert-manager \
                --for=condition=ready pod \
                --selector=app.kubernetes.io/name=cert-manager \
                --timeout=120s
        fi

        # Wait for cert-manager CRDs to be available
        echo "${green}Waiting for cert-manager CRDs to be available...${reset}"
        kubectl wait --for=condition=established --timeout=60s crd/issuers.cert-manager.io
        kubectl wait --for=condition=established --timeout=60s crd/certificates.cert-manager.io
        kubectl wait --for=condition=established --timeout=60s crd/clusterissuers.cert-manager.io

        # Wait for cert-manager webhook to be ready
        echo "${green}Waiting for cert-manager webhook to be ready...${reset}"
        kubectl wait --namespace cert-manager \
            --for=condition=ready pod \
            --selector=app.kubernetes.io/name=webhook \
            --timeout=60s

        # Wait a bit more for cert-manager to be fully ready
        echo "${green}Waiting for cert-manager to be fully ready...${reset}"
        sleep 15

        echo "${green}Installing Rancher...${reset}"
        helm install rancher rancher-latest/rancher \
            --namespace cattle-system \
            --create-namespace \
            -f setup_system/manifests/values-rancher-ingress.yaml \
            --set hostname=rancher.nice.local \
            --set replicas=3

        echo "${green}Waiting for rancher to be ready---------------------------------------------------------------------------${reset}"
        kubectl wait --namespace cattle-system \
                --for=condition=ready pod \
                --selector=app=rancher \
                --timeout=120s
    fi
fi

echo "${green}${bold}Installation completed successfully!${reset}"
echo ""
if [[ "$INSTALL_ARGOCD" == true ]]; then
    echo "${blue}ArgoCD is available at: https://argocd.nice.local${reset}"
    echo "Default admin password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
fi
if [[ "$INSTALL_RANCHER" == true ]]; then
    echo "${blue}Rancher is available at: https://rancher.nice.local${reset}"
    echo "Default admin password: $(kubectl -n cattle-system get secret cattle-system-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
fi

