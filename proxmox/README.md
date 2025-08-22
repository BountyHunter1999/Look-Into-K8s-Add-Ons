# Proxmox

## Setup

- `cp main.auto.tfvars.tmpl main.auto.tfvars`
- Add the proper values to the `main.auto.tfvars` file
- `terraform init`
- `terraform plan`
- `terraform apply`

## API Keys for authentication with promox

1. Go to Datacenter in the left tab
2. Permissions ->
   - Create Groups:
   - Name: Provisioning
   - Comment: Provison Servers
   - Create users:
     - Users ->
       - username: `local_terra`
       - First Name: `local`
       - Last Name: `terra`
       - Email: `local_terra@example.com`
       - Groups: Provisioning
       - Comment: `Terraform user`
   - Roles ->
     - `pveum role add Provisioner -privs "Datastore.Allocate,Datastore.AllocateSpace,Datastore.AllocateTemplate,Datastore.Audit,SDN.Use,Sys.AccessNetwork,Sys.Audit,VM.Allocate,VM.Audit,VM.Backup,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.GuestAgent.Audit,VM.GuestAgent.FileRead,VM.GuestAgent.FileSystemMgmt,VM.GuestAgent.FileWrite,VM.PowerMgmt"`
     - `pveum role delete Provisioner` to delete the role
     - `pveum role list Provisioner` to list the permisisons for the role
   - Add -> Group Permissions:
     - Path: /
     - Group: Provisioning
     - Role: Provisioner
     - Propagate: Yes
   - Create API Tokens: API Tokens ->
     - User: Select the local terra user
     - Token ID: `local_terra_token`
     - Expire: Never (Make it something short)
     - Copy the secret key and save it somewhere safe

## Destroy VMS

- `echo "101,103,104,105" | awk -F',' '{for (i=1;i<=NF;i++) print $i}' | xargs -I{} qm stop {}`
- `echo "101,103,104,105" | awk -F',' '{for (i=1;i<=NF;i++) print $i}' | xargs -I{} qm destroy {}`
