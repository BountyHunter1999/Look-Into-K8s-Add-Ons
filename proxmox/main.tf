resource "proxmox_vm_qemu" "vms" {
    for_each = toset(["dev", "stage", "prod"])
    name = each.value
    target_node = var.target_node
    # This was already created in the Proxmox UI
    clone = var.vm_template

    # VM settings:
    memory = each.key == "prod" ? 4096 : 2048
}