.PHONY: setup

create_cluster:
	kind create cluster --config setup_system/kind/kind-config.yaml


setup:
	bash setup_system/k3s/install.sh