locals {
  environments = ["dev", "stage", "prod"]
}

# resource "proxmox_vm_qemu" "vms" {
#   for_each    = toset(local.environments)
#   name        = each.value
#   target_node = var.target_node
#   # This was already created in the Proxmox UI
#   clone      = var.vm_template
#   full_clone = true

#   # VM settings:
#   memory = each.key == "prod" ? 4096 : 2048

#   cpu {
#     cores   = each.key == "prod" ? 2 : 1
#     sockets = 1
#     type    = "host"
#   }

#   vmid = 300 + index(local.environments, each.value) + 1

#   # Boot order: disk first, then network
#   boot = "order=scsi0;net0"

#   # Enable QEMU guest agent
#   agent = 1

#   # Enable serial console
#   serial {
#     type = "socket"
#     id   = 0
#   }



#   disks {
#     scsi {
#       scsi0 {
#         disk {
#           backup             = true
#           cache              = "none"
#           discard            = true
#           emulatessd         = true
#           iothread           = true
#           mbps_r_burst       = 0.0
#           mbps_r_concurrent  = 0.0
#           mbps_wr_burst      = 0.0
#           mbps_wr_concurrent = 0.0
#           replicate          = true
#           size               = 32
#           storage            = "local-lvm"
#         }
#       }
#     }
#   }

#   bios = "seabios"


#   network {
#     id        = 0
#     bridge    = "vmbr0"
#     firewall  = false
#     link_down = false
#     model     = "virtio"
#   }

# }

resource "proxmox_vm_qemu" "control_server" {
  name        = "control-server"
  target_node = var.target_node
  # This was already created in the Proxmox UI
  clone      = var.vm_template
  full_clone = true

  # VM settings:
  memory = 4096

  vmid = 300


  cpu {
    cores   = 4
    sockets = 1
    type    = "host"
  }

  # Boot order: disk first, then network
  boot = "order=scsi0;net0"

  # Enable QEMU guest agent
  #   agent = 1

  bios = "seabios"


  serial {
    type = "socket"
    id   = 0
  }

  disks {
    scsi {
      scsi0 {
        disk {
          backup             = true
          cache              = "none"
          discard            = true
          emulatessd         = true
          iothread           = true
          mbps_r_burst       = 0.0
          mbps_r_concurrent  = 0.0
          mbps_wr_burst      = 0.0
          mbps_wr_concurrent = 0.0
          replicate          = true
          size               = 80
          storage            = "local-lvm"
        }
      }
    }
  }

  scsihw = "virtio-scsi-single"

  network {
    id       = 0
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = false
  }

  hotplug = "network,disk,usb"

  kvm = true
  #   vm_state = "start_after_create"
}

