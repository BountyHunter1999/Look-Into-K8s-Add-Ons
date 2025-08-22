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
    pm_user = var.proxmox_user
    pm_password = var.proxmox_password
    pm_tls_insecure = true
}
