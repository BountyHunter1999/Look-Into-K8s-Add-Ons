.PHONY: setup

create_cluster:
	kind delete cluster --name nice-cluster
	kind create cluster --config setup_system/kind/kind-config.yaml

setup_other_env:
	k3d cluster create --config setup_system/k3s/k3d-config.yaml

add_cluster_to_argocd: # kubectl config view -o jsonpath='{range .clusters[*]}{.name} -> {.cluster.server}{"\n"}{end}'
	kubectl config set-cluster k3d-dev --server=https://k3d-dev-server-0:6443
	kubectl config set-cluster k3d-prod --server=https://k3d-prod-server-0:6443
	kubectl config set-cluster k3d-stage --server=https://k3d-stage-server-0:6443
	kubectl config set-cluster k3d-mycluster --server=https://k3d-mycluster-server-0:6443
	k3d cluster add dev
	k3d cluster add prod
	k3d cluster add stage

setup_with_k3d:
	bash setup_system/k3s/install.sh

setup_with_kind:
	bash setup_system/kind/install.sh --argocd --rancher

# Only for k3d
access_argo:
	kubectl port-forward service/argocd-server -n argocd 8081:443 --address 0.0.0.0
	echo "access argo"

access_rancher:
	kubectl port-forward service/rancher -n cattle-system 8082:443 --address 0.0.0.0
	echo "access rancher"


#Install Kustomize
install_kustomize:
	GOBIN=$(pwd)/ GO111MODULE=on go install sigs.k8s.io/kustomize/kustomize/v5@latest
