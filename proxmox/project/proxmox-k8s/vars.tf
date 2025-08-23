variable "proxmox_api_url" {
  type    = string
  default = "https://your-proxmox-server:8006/api2/json"
}

variable "proxmox_api_token_id" {
  type    = string
  default = "local_terra@pam!local_terra_token"
}

variable "proxmox_api_token_secret" {
  type = string
}

variable "vm_template" {
  type    = string
  default = "ubuntu-24.04-template"
}

variable "target_node" {
  type    = string
  default = "pve"
}

variable "vm_configs" {
  type = map(object({
    vm_id       = number
    name        = string
    cores       = number
    memory      = number
    vm_state    = string
    bridge      = string
    disk_size   = string
    onboot      = bool
    startup     = string
    network_tag = number
    ipconfig    = string
    ciuser      = string
    cipassword  = string
    sshkeys     = string
  }))

  default = {
    "control_server" = {
      vm_id       = 301
      name        = "controlServer",
      cores       = 4,
      memory      = 8192,
      vm_state    = "running",
      bridge      = "vmbr0",
      disk_size   = "60G", # make sure to have more storage than the tempalte
      onboot      = true,
      startup     = "order=1",
      network_tag = 301,
      ipconfig    = "ip=dhcp",
      ciuser      = "k8sUser"
      cipassword  = "k8sUserpass"
      sshkeys     = "some_public_key"
    }
    "prod" = {
      vm_id       = 302
      name        = "prod",
      cores       = 2,
      memory      = 4096,
      vm_state    = "running",
      bridge      = "vmbr0",
      disk_size   = "20G",
      onboot      = true,
      startup     = "order=2",
      network_tag = 302,
      # ip route to find the gateway
      ipconfig   = "ip=192.168.0.203/24,gw=192.168.0.1",
      ciuser     = "k8sUser"
      cipassword = "k8sUserpass"
      sshkeys    = "some_public_key"
    },
    "dev" = {
      vm_id       = 303
      name        = "dev",
      cores       = 1,
      memory      = 2048,
      vm_state    = "running",
      bridge      = "vmbr0",
      disk_size   = "15G",
      onboot      = true,
      startup     = "order=3",
      network_tag = 303,
      ipconfig    = "ip=dhcp",
      ciuser      = "k8sUser"
      cipassword  = "k8sUserpass"
      sshkeys     = "some_public_key"
    },
    "stage" = {
      vm_id       = 304
      name        = "stage",
      cores       = 1,
      memory      = 2048,
      vm_state    = "running",
      bridge      = "vmbr0",
      disk_size   = "15G", 
      onboot      = true,
      startup     = "order=4",
      network_tag = 304,
      ipconfig    = "ip=dhcp",
      ciuser      = "k8sUser"
      cipassword  = "k8sUserpass"
      sshkeys     = "some_public_key"
    },
  }
}
