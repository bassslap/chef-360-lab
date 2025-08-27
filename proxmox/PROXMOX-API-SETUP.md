# Proxmox API Token Setup Guide

## 🔧 Create API Token for Terraform

The error shows that the API token 'terraform' doesn't exist for user 'terraform@pve'. Here's how to create it:

### 1. Create User (if not exists)

1. **Login to Proxmox Web Interface**
   - Go to `https://192.168.220.200:8006`
   - Login with your admin credentials

2. **Navigate to User Management**
   - Click `Datacenter` in the left panel
   - Click `Permissions` → `Users`

3. **Create Terraform User**
   - Click `Add` button
   - **User name**: `terraform`
   - **Realm**: `pve`
   - **Password**: (set a password or leave blank for token-only access)
   - Click `Add`

### 2. Create API Token

1. **Select the User**
   - Click on `terraform@pve` user in the list
   - Click `API Tokens` tab

2. **Add API Token**
   - Click `Add` button
   - **Token ID**: `terraform`
   - **Privilege Separation**: **UNCHECK** this box (important!)
   - Click `Add`

3. **Copy the Token**
   - Proxmox will show a token like: `04b4b8ef-d38d-40a8-b9bd-ed3cdd3ad7e1`
   - **Save this token** - you can't see it again!

### 3. Set Permissions

1. **Navigate to Permissions**
   - Click `Datacenter` in left panel
   - Click `Permissions`

2. **Add Permission**
   - Click `Add` → `User Permission`
   - **Path**: `/` (root)
   - **User**: `terraform@pve`
   - **Role**: `Administrator` (or create custom role)
   - Click `Add`

### 4. Update terraform.tfvars

Use the token you copied in step 2:

```hcl
proxmox = {
  api_url          = "https://YOUR-IP:8006/api2/json"
  user             = "terraform@pve"
  api_token_id     = "terraform@pve!terraform"
  api_token_secret = "XXXXXXXXX"  # Replace with your actual token
  tls_insecure     = true
  # ... rest of config
}
```

### 5. Test Connection

Run this to test your API access:

```bash
curl -k -H "Authorization: PVEAPIToken=terraform@pve!terraform=04b4b8ef-d38d-40a8-b9bd-ed3cdd3ad7e1" \
  https://192.168.220.200:8006/api2/json/version
```

You should see version information if authentication works.

## 🚨 Troubleshooting

### Common Issues:

1. **"no such token"** - Token doesn't exist, create it in step 2
2. **"permission denied"** - User needs Administrator role or specific permissions
3. **"Privilege Separation"** - Must be UNCHECKED for full access
4. **Wrong format** - Token ID must be `user@realm!tokenname`

### Required Permissions for Terraform:

If you don't want to use Administrator role, create a custom role with:
- VM.Allocate
- VM.Config.Disk
- VM.Config.Memory
- VM.Config.Network
- VM.Config.Options
- VM.Monitor
- VM.PowerMgmt
- Datastore.Allocate

## ✅ Once Setup Complete

Run `terraform plan` again and it should work!
