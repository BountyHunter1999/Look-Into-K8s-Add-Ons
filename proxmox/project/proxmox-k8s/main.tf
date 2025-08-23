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

  boot = "order=scsi0;net0"

  # machine = "q35"

  # boot = "order=ide2;scsi0" # has to be the same as the OS disk of the template

  clone      = var.vm_template
  full_clone = true
  bios       = "seabios"
  agent      = 1
  scsihw     = "virtio-scsi-single"


  os_type = "cloud-init"
  memory  = each.value.memory

  # vm_state = each.value.vm_state
  # Automatically reboot the VM if any of the modified parameters requires a reboot to take effect.
  automatic_reboot = true
  onboot           = each.value.onboot
  # startup          = each.value.startup

  # cloud init configuration
  #https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/guides/cloud-init%20getting%20started.md
  # cicustom   = "vendor=local:snippets/qemu-guest-agent.yml" # /var/lib/vz/snippets/qemu-guest-agent.yml  cicustom = ""
  ipconfig0  = each.value.ipconfig
  skip_ipv6  = true
  nameserver = "1.1.1.1 8.8.8.8"
  ciuser     = each.value.ciuser
  cipassword = each.value.cipassword
  ciupgrade  = true
  sshkeys    = each.value.sshkeys
  # force_recreate_on_change_of = "cipassword"

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
        # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
        cloudinit {

          storage = "local-lvm"
        }
      }

    }
  }
  network {
    id       = 0
    model    = "virtio"
    bridge   = each.value.bridge
    firewall = true
    tag      = each.value.network_tag
  }

  cpu {
    cores   = each.value.cores
    sockets = 1
    type    = "x86-64-v2-AES"
  }

  serial {
    id   = 0
    type = "socket"
  }

  efidisk {
    efitype = "4m"
    storage = "local-lvm"
  }
}

