#!/bin/bash
TF_CMD="docker compose run --rm terraform"

terraform_plan() {
    local TERRAFORM_ENV="$1"
    export TERRAFORM_ENV

    $TF_CMD init -upgrade
    $TF_CMD plan
}

terraform_apply() {
    local TERRAFORM_ENV="$1"
    export TERRAFORM_ENV

    $TF_CMD apply -auto-approve
}

terraform_destroy() {
    local TERRAFORM_ENV="$1"
    export TERRAFORM_ENV

    $TF_CMD destroy
}

terraform_plan "proxmox-k8s"
terraform_apply "proxmox-k8s"
# terraform_destroy "proxmox-k8s"