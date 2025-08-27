# Proxmox Chef 360 - Simplified for Lab Use

## 🎯 Perfect for Local Labs

This Proxmox version is optimized for local lab environments where you want:
- **Simple SSL**: Self-signed certificates (no Let's Encrypt complexity)
- **Local Access**: Direct IP access (no public DNS required)
- **Full Control**: Complete infrastructure ownership
- **Cost Effective**: No cloud provider fees

## 🔧 What's Different from Azure

### Simplified SSL Approach
- ✅ **Self-signed certificates** generated automatically
- ✅ **No ACME/Let's Encrypt** complexity
- ✅ **Perfect for labs** where browser warnings are acceptable
- ✅ **1-year validity** for long-term lab use

### Local Network Focus
- ✅ **Direct IP access** to all services
- ✅ **No public DNS** requirements
- ✅ **DHCP networking** with VLAN support
- ✅ **Local domain** (.local.lab) for certificate generation

### Infrastructure Control
- ✅ **Your hardware** - complete control
- ✅ **Proxmox templates** - reusable VM images
- ✅ **Local storage** - no cloud storage costs
- ✅ **Network flexibility** - bridges, VLANs, etc.

## 🚀 Quick Start

1. **Create Template**: `./scripts/setup-template.sh`
2. **Configure**: Edit `terraform.tfvars` with your Proxmox details
3. **Deploy**: `terraform apply`
4. **Access**: Use the IP addresses from terraform outputs

## 📋 What Gets Created

### VMs
- **Chef 360**: 4 cores, 32GB RAM, 500GB disk
- **Workstation**: 2 cores, 4GB RAM, 40GB disk  
- **Nodes**: 2 Linux nodes ready for management

### Certificates
- **Self-signed SSL** certificate for Chef 360
- **Saved locally** in `./tmp/` directory
- **Ready to upload** to Chef 360 admin console

### Network
- **DHCP assignment** for all VMs
- **Same bridge** for easy communication
- **Optional VLAN** support

## 🔍 Access URLs (Example)

After deployment, access Chef 360 via:
- **Admin Console**: `http://192.168.1.100:30000`
- **Platform API**: `http://192.168.1.100:31000`  
- **Mailpit**: `http://192.168.1.100:31101`

*(Replace with actual IPs from terraform outputs)*

## 💡 Lab Benefits

### Cost
- **Zero cloud fees** after hardware investment
- **Unlimited usage** within your hardware limits
- **No bandwidth charges** for internal traffic

### Learning
- **Full stack control** - understand every component
- **Proxmox skills** - valuable virtualization knowledge
- **Network management** - hands-on networking experience

### Flexibility
- **Snapshot VMs** for testing
- **Clone environments** easily
- **Resource allocation** as needed
- **Persistent lab** environment

This approach gives you all the Chef 360 functionality while keeping things simple and lab-friendly!
