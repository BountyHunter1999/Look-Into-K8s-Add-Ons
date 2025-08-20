#!/bin/bash

# set -x

# Function to ask for user confirmation
ask_install() {
    local component=$1
    local description=$2
    
    echo "=========================================="
    echo "Install $component?"
    echo "Description: $description"
    echo "=========================================="
    
    while true; do
        read -p "Do you want to install $component? (y/n): " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n).";;
        esac
    done
}

# Install k3d
if ! command -v k3d &> /dev/null; then
    echo "Installing k3d..."
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Create k3d cluster
echo "Creating k3d cluster..."
# Expose 80/443 on the host for local ingress (Traefik is enabled by default in k3s)
k3d cluster create mycluster

# Prepare Helm repos (cert-manager)
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager and configure local self-signed ClusterIssuer
echo "Installing cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true

# echo "Configuring local TLS ClusterIssuer..."
# kubectl apply -f ../manifests/cert-manager-local-issuer.yaml

# Ask about ArgoCD installation
if ask_install "ArgoCD" "GitOps continuous delivery tool for Kubernetes"; then
    echo "Installing ArgoCD..."
    
    # Add ArgoCD repository
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    
    # helm upgrade -i argo-cd argo/argo-cd --namespace argocd --create-namespace -f manifests/values-argocd-ingress.yaml
    # helm upgrade -i argo-cd argo/argo-cd --namespace argocd --create-namespace -f manifests/values-argocd-ingress.yaml

    helm upgrade --install argocd argo/argo-cd --namespace argocd --create-namespace --values=setup_system/manifests/values-argocd-ingress.yaml

    # Wait for ArgoCD to be ready
    kubectl wait --namespace argocd \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/name=argocd-server \
      --timeout=90s
    
    echo "ArgoCD installed successfully!"
    # kubectl port-forward svc/argo-cd-argocd-server 8080:80 -n argocd & 
    echo "Default admin password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
else
    echo "Skipping ArgoCD installation."
fi

# Ask about Rancher installation
if ask_install "Rancher" "Kubernetes management platform"; then
    echo "Installing Rancher..."
    
    # Add Rancher repository
    helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
    helm repo update

    # Install/upgrade Rancher with local ingress + TLS via cert-manager
    helm upgrade --install rancher rancher-latest/rancher \
      --namespace cattle-system \
      --create-namespace \
       -f setup_system/manifests/values-rancher-ingress.yaml \
      --set hostname=rancher.nice.local \
      --set replicas=1 \
      --set bootstrapPassword=admin123 \
      --set ingress.tls.source=ingress

    kubectl wait --namespace cattle-system \
      --for=condition=ready pod \
      --selector=app=rancher \
      --timeout=90s

    echo "Rancher installed successfully!"
    echo "You can access Rancher at: https://rancher.nice.local"
    echo "Default admin password: admin123"
else
    echo "Skipping Rancher installation."
fi

echo "Installation completed!"
echo "=========================================="
echo "Summary:"
echo "- k3d cluster 'mycluster' created"
echo "- Check the output above for installation status of ArgoCD and Rancher"
echo "=========================================="