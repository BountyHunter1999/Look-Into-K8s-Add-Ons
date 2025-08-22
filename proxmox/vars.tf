variable "proxmox_api_url" {
    type = string
    default = "https://your-proxmox-server:8006/api2/json"
}

variable "proxmox_api_token_id" {
    type = string
    default = "local_terra@pam!local_terra_token"
}

variable "proxmox_api_token_secret" {
    type = string
}

variable "vm_template" {
    type = string
    default = "ubuntu-24.04-template"
}

variable "target_node" {
    type = string
    default = "pve"
}

