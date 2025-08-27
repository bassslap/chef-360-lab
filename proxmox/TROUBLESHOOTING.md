# Troubleshooting Proxmox Provider Plugin Crash

## Current Error
The Terraform Proxmox provider crashed with error:
```
panic: interface conversion: interface {} is string, not float64
```

This typically happens when:
1. The VM template doesn't exist
2. The template has incorrect configuration  
3. There's a type mismatch in the template metadata

## Resolution Steps

### Step 1: Verify Template Exists
Log into your Proxmox web interface and check:
1. Go to your `proxmox` node
2. Look for a VM template named `ubuntu-22.04-cloud`
3. If it doesn't exist, you need to create it

### Step 2: Create Ubuntu Template (If Missing)

**SSH to your Proxmox host and run:**

```bash
# Download Ubuntu cloud image
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create VM (use a different ID if 9000 is taken)
qm create 9000 --name "ubuntu-22.04-cloud" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import the disk
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Configure the VM
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000
```

### Step 3: Alternative Template Names
If you have a different Ubuntu template, update `terraform.tfvars`:

Common template names:
- `ubuntu-22.04-cloud`
- `ubuntu-cloud`
- `ubuntu2204`
- `ubuntu-22-04-cloud`

### Step 4: Check Template in Web UI
1. Login to Proxmox web interface
2. Navigate to your node
3. Look for templates (they have a different icon)
4. Note the exact name

### Step 5: Update Configuration
Update the template name in your `terraform.tfvars`:
```hcl
template_name = "your-exact-template-name"
```

### Step 6: Clean State and Retry
```bash
# Remove any partial state
terraform state list | grep proxmox_vm_qemu | xargs -I {} terraform state rm {}

# Try again
terraform apply
```

## Alternative: Using VM ID Instead of Name
If the template name continues to cause issues, you can try using the VM ID:

```hcl
# In your modules, change from:
clone = var.networking.template_name

# To:
clone = "9000"  # or whatever your template ID is
```

## Checking Logs
For more details, check Proxmox logs:
```bash
# On Proxmox host
tail -f /var/log/pve/tasks/active
```
