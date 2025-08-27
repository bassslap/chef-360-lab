#!/bin/bash

# Script to create Ubuntu 22.04 template via Proxmox API
set -e

# Configuration
PROXMOX_HOST="192.168.220.200"
API_TOKEN="terraform@pve!terraform=a1c550c3-c05d-4e2f-b59f-72df158f86bb"
VMID="9000"
VMNAME="ubuntu-22.04-template"
NODE="proxmox"
STORAGE="local-lvm"

echo "=== Creating Ubuntu 22.04 Template via API ==="
echo ""

# Function to make API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -n "$data" ]; then
        curl -k -s -X $method \
            -H "Authorization: PVEAPIToken=$API_TOKEN" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -d "$data" \
            "https://$PROXMOX_HOST:8006/api2/json$endpoint"
    else
        curl -k -s -X $method \
            -H "Authorization: PVEAPIToken=$API_TOKEN" \
            "https://$PROXMOX_HOST:8006/api2/json$endpoint"
    fi
}

echo "1. Checking if VM $VMID already exists..."
response=$(api_call GET "/nodes/$NODE/qemu/$VMID" 2>/dev/null || echo "")

if echo "$response" | grep -q '"data"'; then
    echo "VM $VMID already exists. Checking if it's a template..."
    is_template=$(echo "$response" | jq -r '.data.template // false' 2>/dev/null || echo "false")
    
    if [ "$is_template" = "1" ] || [ "$is_template" = "true" ]; then
        echo "Template $VMID already exists and is ready to use!"
        exit 0
    else
        echo "VM $VMID exists but is not a template. Please delete it first or use a different VMID."
        exit 1
    fi
fi

echo "2. Downloading Ubuntu 22.04 cloud image..."
echo "   This needs to be done on the Proxmox host. Please run:"
echo ""
echo "   ssh root@$PROXMOX_HOST"
echo "   cd /var/lib/vz/template/iso"
echo "   wget -O ubuntu-22.04-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
echo ""
echo "3. Creating VM template using Proxmox commands:"
echo "   Run these commands on your Proxmox host:"
echo ""

cat << 'EOF'
# Create the VM
qm create 9000 --name ubuntu-22.04-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import the cloud image (make sure you downloaded it first)
cd /var/lib/vz/template/iso
qm disk import 9000 ubuntu-22.04-server-cloudimg-amd64.img local-lvm

# Attach the disk
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0

# Configure the VM
qm set 9000 --scsihw virtio-scsi-pci --boot order=scsi0
qm set 9000 --agent enabled=1
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0

# Convert to template
qm template 9000

echo "Template 9000 created successfully!"
EOF

echo ""
echo "4. Alternative: If you have SSH access, I can generate the exact commands:"

# Create a script to run on Proxmox host
cat > create_template_on_proxmox.sh << 'SCRIPT'
#!/bin/bash
set -e

VMID=9000
echo "Creating Ubuntu 22.04 template..."

# Check if VM already exists
if qm status $VMID >/dev/null 2>&1; then
    echo "VM $VMID already exists. Please remove it first: qm destroy $VMID"
    exit 1
fi

# Download cloud image if not present
cd /var/lib/vz/template/iso
if [ ! -f ubuntu-22.04-server-cloudimg-amd64.img ]; then
    echo "Downloading Ubuntu 22.04 cloud image..."
    wget -O ubuntu-22.04-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
fi

# Create VM
echo "Creating VM $VMID..."
qm create $VMID --name ubuntu-22.04-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import disk
echo "Importing cloud image..."
qm disk import $VMID ubuntu-22.04-server-cloudimg-amd64.img local-lvm

# Configure VM
echo "Configuring VM..."
qm set $VMID --scsi0 local-lvm:vm-$VMID-disk-0
qm set $VMID --scsihw virtio-scsi-pci --boot order=scsi0
qm set $VMID --agent enabled=1
qm set $VMID --ide2 local-lvm:cloudinit
qm set $VMID --serial0 socket --vga serial0

# Convert to template
echo "Converting to template..."
qm template $VMID

echo "Template $VMID created successfully!"
echo "You can now run 'tofu apply' to deploy Chef 360"
SCRIPT

chmod +x create_template_on_proxmox.sh

echo ""
echo "Created script: create_template_on_proxmox.sh"
echo "Copy this script to your Proxmox host and run it as root:"
echo ""
echo "scp create_template_on_proxmox.sh root@$PROXMOX_HOST:/"
echo "ssh root@$PROXMOX_HOST './create_template_on_proxmox.sh'"
echo ""
echo "Or manually run the commands shown above on your Proxmox host."
