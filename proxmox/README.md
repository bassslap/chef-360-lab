# Proxmox Terraform Plan for Chef 360 Platform

Version: 0.3.0

## This is specific to the Proxmox plan

This plan provisions Chef 360 infrastructure on Proxmox VE (Virtual Environment). Unlike cloud providers, Proxmox gives you complete control over your virtualization infrastructure.

## Prerequisites

### Proxmox VE Setup
1. **Proxmox VE 8.0+** installed and configured
2. **Ubuntu 22.04 Cloud Template** created in Proxmox
3. **Network Bridge** configured (usually `vmbr0`)
4. **Storage Pool** configured (local-lvm, NFS, etc.)
5. **SSH Key Pair** generated

### Terraform Requirements
- Terraform >= 1.8.5
- Proxmox provider access configured

## Quick Start

### 1. Prepare Proxmox Template

First, create an Ubuntu 22.04 cloud template in Proxmox:

```bash
# Download Ubuntu 22.04 cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create VM template
qm create 9000 --name ubuntu-22.04-cloud --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm template 9000
```

### 2. Configure Terraform Variables

```bash
cd proxmox/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

### 3. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

## Configuration

### Required Variables

Update `terraform.tfvars` with your environment-specific values:

```hcl
proxmox = {
  api_url       = "https://your-proxmox-host:8006/api2/json"
  user          = "terraform@pve"
  password      = "your-password"
  node_name     = "pve"
  storage       = "local-lvm"
  bridge        = "vmbr0"
  template_name = "ubuntu-22.04-cloud"
  # ... other settings
}

chef360 = {
  replicated_key = "your-license-key"
  # ... other settings
}
```

## Architecture

### Components Created

1. **Chef 360 VM**
   - 4 cores, 8GB RAM, 100GB disk (configurable)
   - Chef 360 platform with all services
   - Ports: 30000 (admin), 31000 (platform), 31050 (courier), 31080 (skills), 31101 (mailpit)

2. **Workstation VM**
   - 2 cores, 4GB RAM, 40GB disk (configurable)
   - Management tools and CLI utilities
   - PowerShell and Chef 360 CLI tools

3. **Node VMs**
   - Configurable number of Linux/Windows nodes
   - Ready for Chef 360 management

### Network Configuration

- All VMs connected to the same bridge (`vmbr0` by default)
- DHCP IP assignment (configurable to static)
- Optional VLAN tagging support

## Post-Deployment

### Access Your Environment

After deployment, you'll see outputs similar to:

```
Chef360_Dashboard = "http://192.168.1.100:30000"
Chef360_Platform_URL = "http://192.168.1.100:31000"
Chef360_Private_IP_Address = "192.168.1.100"
Workstation_IP_Address = "192.168.1.101"
SSL_Certificate_Files = {
  "certificate" = "./tmp/chef360-demo.local.lab.chain.pem"
  "private_key" = "./tmp/chef360-demo.local.lab.key.pem"
  "common_name" = "chef360-demo.local.lab"
}
```

### Complete Chef 360 Setup

1. **Access Replicated Admin Console**
   ```bash
   # Use the actual IP address from outputs
   open http://192.168.1.100:30000
   ```

2. **Configure SSL Certificates**
   - Upload the generated certificates from `./tmp/` directory
   - Use the files shown in the `SSL_Certificate_Files` output
   - Certificates are auto-generated during terraform apply

3. **Complete Chef 360 Installation**
   - Follow the web-based setup wizard
   - Configure your tenant and organization
   - Use the VM's IP address as your endpoint URL

### SSH Access

Connect to your VMs using the SSH keys you specified:

```bash
# Connect to Chef 360 VM
ssh -i ~/.ssh/your-key ubuntu@chef360-ip

# Connect to Workstation
ssh -i ~/.ssh/your-key ubuntu@workstation-ip
```

## Differences from Azure Version

### Advantages
- **Full Control**: Complete control over virtualization layer
- **Cost Effective**: No cloud provider costs
- **Network Flexibility**: Full control over networking
- **Storage Options**: Multiple storage backend support
- **Simple SSL**: Self-signed certificates perfect for lab environments

### Considerations
- **Manual Template Management**: Need to maintain VM templates
- **Network Configuration**: Requires understanding of Proxmox networking
- **Local Access**: Designed for local lab use (no public DNS needed)
- **Self-Signed SSL**: Perfect for labs, browsers will show security warning

## Customization

### VM Specifications

Adjust VM resources in `terraform.tfvars`:

```hcl
chef360 = {
  cores     = 8      # More CPU for larger deployments
  memory    = 16384  # More memory for larger deployments
  disk_size = "200G" # Larger disk for more data
}
```

### Network Configuration

```hcl
proxmox = {
  bridge   = "vmbr1"  # Different network bridge
  vlan_tag = 100      # VLAN tagging
}
```

### Multiple Nodes

```hcl
platform = {
  linux_node_count   = 5  # More Linux nodes
  windows_node_count = 2  # Windows nodes (requires Windows template)
}
```

## Troubleshooting

### Helper Scripts

The `scripts/` directory contains utility scripts for common operations:

```bash
# Template management
./scripts/create-ubuntu-template.sh  # Create new template
./scripts/validate-template.sh       # Check template status
./scripts/setup-template.sh         # Configure template

# VM cleanup
./scripts/cleanup-stale-vms.sh      # Remove orphaned VMs
./scripts/remote-cleanup.sh         # Remote cleanup operations

# Utility scripts
./scripts/find-node-name.sh         # Discover node names
```

See `scripts/README.md` for detailed documentation of all available scripts.

### Common Issues

1. **Template Not Found**
   - Ensure Ubuntu cloud template exists
   - Check template name matches `template_name` variable

2. **Permission Denied**
   - Verify Proxmox user has VM creation permissions
   - Check API token permissions

3. **Network Issues**
   - Verify bridge name exists
   - Check VLAN configuration if using VLANs

4. **Storage Issues**
   - Confirm storage pool exists and has space
   - Check storage permissions

### Logs and Debugging

```bash
# Check terraform logs
export TF_LOG=DEBUG
terraform apply

# Check VM logs in Proxmox
# Web UI > VM > Monitor > Log

# SSH into VMs to check installation logs
ssh ubuntu@vm-ip
tail -f /home/ubuntu/chef-360-install.log
```

## Migration from Azure

If migrating from the Azure version:

1. **Copy Configuration**: Use your existing `terraform.tfvars` as reference
2. **Update Variables**: Convert Azure-specific settings to Proxmox equivalents  
3. **Backup Data**: Export any Chef 360 configuration before migration
4. **Test Environment**: Deploy in test environment first

## Support

For issues specific to:
- **Proxmox**: Check Proxmox VE documentation
- **Chef 360**: Refer to Chef 360 documentation
- **Terraform Provider**: Check telmate/proxmox provider documentation

This Proxmox implementation provides the same Chef 360 functionality as the Azure version while giving you complete infrastructure control.


# Progress CHEF 360 install guides and reference
- **Install Chef360 Platform Server**: https://docs.chef.io/360/1.4/get_started/install_server/
- **Lost password (5 minutes)** http://<FQDN>31000/app/login/forgot-password
