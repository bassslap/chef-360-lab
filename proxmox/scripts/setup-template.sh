#!/bin/bash

# Chef 360 Proxmox Template Setup Script
# This script helps create the Ubuntu cloud template needed for the Terraform deployment

set -e

echo "🚀 Chef 360 Proxmox Template Setup"
echo "=================================="

# Configuration
TEMPLATE_ID=${1:-9000}
TEMPLATE_NAME="ubuntu-22.04-cloud"
UBUNTU_VERSION="22.04"
STORAGE=${2:-"local-lvm"}
BRIDGE=${3:-"vmbr0"}

echo "📋 Configuration:"
echo "   Template ID: $TEMPLATE_ID"
echo "   Template Name: $TEMPLATE_NAME"
echo "   Storage: $STORAGE"
echo "   Bridge: $BRIDGE"
echo ""

# Check if running on Proxmox node
if ! command -v qm &> /dev/null; then
    echo "❌ Error: This script must be run on a Proxmox VE node"
    echo "   The 'qm' command is not available"
    exit 1
fi

# Check if template already exists
if qm list | grep -q "^$TEMPLATE_ID"; then
    echo "⚠️  Warning: VM/Template with ID $TEMPLATE_ID already exists"
    read -p "Do you want to remove it and continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing existing template..."
        qm destroy $TEMPLATE_ID
    else
        echo "❌ Aborted"
        exit 1
    fi
fi

echo "📥 Downloading Ubuntu $UBUNTU_VERSION cloud image..."
CLOUD_IMAGE="jammy-server-cloudimg-amd64.img"
if [ ! -f "$CLOUD_IMAGE" ]; then
    wget -q --show-progress "https://cloud-images.ubuntu.com/jammy/current/$CLOUD_IMAGE"
else
    echo "   ✅ Image already downloaded"
fi

echo "🔧 Creating VM template..."

# Create VM
echo "   Creating VM $TEMPLATE_ID..."
qm create $TEMPLATE_ID \
    --name $TEMPLATE_NAME \
    --memory 2048 \
    --cores 2 \
    --net0 virtio,bridge=$BRIDGE

# Import disk
echo "   Importing disk image..."
qm importdisk $TEMPLATE_ID $CLOUD_IMAGE $STORAGE

# Configure VM
echo "   Configuring VM settings..."
qm set $TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$TEMPLATE_ID-disk-0
qm set $TEMPLATE_ID --boot c --bootdisk scsi0
qm set $TEMPLATE_ID --ide2 $STORAGE:cloudinit
qm set $TEMPLATE_ID --serial0 socket --vga serial0
qm set $TEMPLATE_ID --agent enabled=1

# Convert to template
echo "   Converting to template..."
qm template $TEMPLATE_ID

echo "✅ Template creation completed!"
echo ""
echo "📋 Template Details:"
echo "   ID: $TEMPLATE_ID"
echo "   Name: $TEMPLATE_NAME"
echo "   Storage: $STORAGE"
echo "   Network: $BRIDGE"
echo ""
echo "🎯 Next Steps:"
echo "1. Update your terraform.tfvars file:"
echo "   proxmox = {"
echo "     template_name = \"$TEMPLATE_NAME\""
echo "     storage       = \"$STORAGE\""
echo "     bridge        = \"$BRIDGE\""
echo "     # ... other settings"
echo "   }"
echo ""
echo "2. Run terraform deployment:"
echo "   cd /path/to/chef-360-core/proxmox"
echo "   terraform init"
echo "   terraform plan"
echo "   terraform apply"
echo ""
echo "🧹 Cleanup:"
echo "You can remove the downloaded image file if desired:"
echo "rm $CLOUD_IMAGE"
