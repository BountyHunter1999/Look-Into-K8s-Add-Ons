# https://github.com/Telmate/terraform-provider-proxmox
terraform {
    required_providers {
        proxmox = {
            source = "telmate/proxmox"
            version = "3.0.2-rc03"
        }
    }
}

provider "proxmox" {
    pm_api_url = var.proxmox_api_url
    pm_api_token_id = var.proxmox_api_token_id
    pm_api_token_secret = var.proxmox_api_token_secret
    pm_tls_insecure = true

    # Required for Proxmox version 9 or greater as VM.Monitor is removed
    # https://github.com/Telmate/terraform-provider-proxmox/issues/1365
    pm_minimum_permission_check = false
}
