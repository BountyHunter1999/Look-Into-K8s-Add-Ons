.PHONY: setup

create_cluster:
	kind delete cluster --name nice-cluster
	kind create cluster --config setup_system/kind/kind-config.yaml

setup:
	bash setup_system/kind/install.sh --argocd --rancher