locals {
  environments = ["dev", "stage", "prod"]
}

# https://registry.terraform.io/providers/Telmate/proxmox/latest/docs
# resource "proxmox_vm_qemu" "vms" {
#   for_each = var.vm_configs

#   vmid        = each.value.vm_id
#   name        = each.value.name
#   target_node = var.target_node

#   clone      = var.vm_template
#   full_clone = true
#   bios       = "ovmf"
#   agent      = 1
#   scsihw     = "virtio-scsi-single"

#   os_type = "ubuntu"
#   memory  = each.value.memory

#   vm_state = each.value.vm_state

#   disks {
#     scsi {
#       scsi0 {
#         disk {
#           size    = each.value.disk_size
#           storage = "local-lvm"
#           format  = "qcow2"
#         }
#       }
#     }
#   }

#   cpu {
#     cores   = each.value.cores
#     sockets = 1
#     type    = "host"
#   }
# }


resource "proxmox_vm_qemu" "cloudinit-vms" {
  for_each = var.vm_configs

  vmid        = each.value.vm_id
  name        = each.value.name
  target_node = var.target_node

  clone      = var.vm_template
  full_clone = true
  bios       = "ovmf"
  agent      = 1
  scsihw     = "virtio-scsi-single"

  os_type = "cloud-init"
  memory  = each.value.memory

  vm_state = each.value.vm_state
  onboot   = each.value.onboot
  startup  = each.value.startup

  # cloud init configuration
  ipconfig0  = each.value.ipconfig
  skip_ipv6  = true
  ciuser     = each.value.ciuser
  cipassword = each.value.cipassword
  sshkeys    = each.value.sshkeys

  disks {
    scsi {
      scsi0 {
        disk {
          size      = each.value.disk_size
          storage   = "local-lvm"
          replicate = true
        }
      }
    }

    ide {
      ide0 {
        cdrom {
          file = "cloudinit.iso"
        }
      }
    }
  }

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "host"
  }

  serial {
    id   = 0
    type = "socket"
  }

  network {
    id       = 0
    model    = "virtio"
    bridge   = each.value.bridge
    firewall = true
    tag      = each.value.network_tag
  }
}

