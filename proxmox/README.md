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
   - Create users:
     - Users ->
       - username: `local_terra`
       - First Name: `local`
       - Last Name: `terra`
       - Email: `local_terra@example.com`
       - Comment: `Terraform user`
   - Create API Tokens: API Tokens ->
     - User: Select the local terra user
     - Token ID: `local_terra_token`
     - Expire: Never (Make it something short)
     - Copy the secret key and save it somewhere safe
