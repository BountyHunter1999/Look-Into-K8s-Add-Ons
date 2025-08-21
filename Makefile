.PHONY: setup

create_cluster:
	kind delete cluster --name nice-cluster
	kind create cluster --config setup_system/kind/kind-config.yaml

setup_other_env:
	k3d cluster delete dev || true
	k3d cluster delete prod || true
	k3d cluster delete stage || true
	k3d cluster create dev
	k3d cluster create prod
	k3d cluster create stage
	kubectl config use-context k3d-mycluster

setup_with_k3d:
	bash setup_system/k3s/install.sh

setup_with_kind:
	bash setup_system/kind/install.sh --argocd --rancher

# Only for k3d
access_argo:
	kubectl port-forward service/argocd-server -n argocd 8081:443 
	echo "access argo"

access_rancher:
	kubectl port-forward service/rancher -n cattle-system 8082:443
	echo "access rancher"


#Install Kustomize
install_kustomize:
	GOBIN=$(pwd)/ GO111MODULE=on go install sigs.k8s.io/kustomize/kustomize/v5@latest
