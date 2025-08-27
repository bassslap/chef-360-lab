# Creating Ubuntu 22.04 Cloud Template in Proxmox

You need to create an Ubuntu 22.04 cloud-init template before deploying the Chef 360 infrastructure.

## Quick Method (Recommended)

### 1. Download Ubuntu Cloud Image
```bash
# SSH to your Proxmox host and run:
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
```

### 2. Create VM Template
```bash
# Create a new VM (using ID 9000, adjust if needed)
qm create 9000 --name "ubuntu-22.04-cloud" --memory 16384 --cores 4 --net0 virtio,bridge=vmbr0

# Import the disk image
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Attach the disk
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Configure cloud-init
qm set 9000 --ide2 local-lvm:cloudinit

# Set boot disk
qm set 9000 --boot c --bootdisk scsi0

# Add serial console
qm set 9000 --serial0 socket --vga serial0

# Enable QEMU guest agent
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000
```

### 3. Verify Template Creation
```bash
# List templates to verify
qm list | grep template
```

You should see `ubuntu-22.04-cloud` listed as a template.

## Alternative: Web UI Method

1. **Download Image**: Download the cloud image to your local machine from: 
   https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

2. **Upload to Proxmox**: 
   - Go to your Proxmox web interface
   - Navigate to your node → local storage → ISO Images
   - Upload the downloaded image

3. **Create VM from Web UI**:
   - Create New VM with ID 9000
   - Name: `ubuntu-22.04-cloud`
   - Use the uploaded image as disk
   - Configure cloud-init settings
   - Convert to template

## After Template Creation

Once the template is created, re-run the Terraform deployment:

```bash
cd /path/to/your/proxmox/folder
terraform apply
```

## Template Requirements

The template name in your `terraform.tfvars` should match exactly:
```
template_name = "ubuntu-22.04-cloud"
```

If you use a different name, update the `template_name` variable in your `terraform.tfvars` file.
