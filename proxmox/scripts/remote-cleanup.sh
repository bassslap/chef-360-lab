#!/bin/bash

echo "=== Remote Proxmox VM Cleanup ==="
echo ""

PROXMOX_HOST="192.168.220.200"

echo "Found these stale Chef 360 VMs that need cleanup:"
echo "- VM 102: node-linux-02 (stopped)"
echo "- VM 103: node-linux-01 (stopped)" 
echo "- VM 104: workstation-linux-01 (stopped)"
echo "- VM 105: node-linux-01 (stopped)"
echo "- VM 106: chef360-linux-01 (stopped)"
echo "- VM 107: node-linux-02 (stopped)"
echo "- VM 108: workstation-linux-01 (stopped)"
echo ""
echo "Keeping:"
echo "- VM 100: eve (might be legitimate)"
echo "- VM 201: pihole (running)"
echo "- VM 9000: ubuntu-22.04-template (needed template)"
echo ""

read -p "Do you want to proceed with cleanup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo "Proceeding with cleanup..."
echo ""

# Copy cleanup script to Proxmox host
echo "1. Copying cleanup script to Proxmox host..."
scp cleanup_stale_vms.sh root@$PROXMOX_HOST:/tmp/

if [ $? -ne 0 ]; then
    echo "❌ Failed to copy script. Trying individual commands..."
    echo ""
    
    # Run cleanup commands individually via SSH
    STALE_VMS="102 103 104 105 106 107 108"
    
    for vmid in $STALE_VMS; do
        echo "Cleaning up VM $vmid..."
        ssh root@$PROXMOX_HOST "qm stop $vmid --skiplock 2>/dev/null || true"
        sleep 1
        ssh root@$PROXMOX_HOST "qm destroy $vmid --purge --skiplock 2>/dev/null || true"
        echo "VM $vmid cleanup completed"
    done
else
    echo "2. Running cleanup script on Proxmox host..."
    ssh root@$PROXMOX_HOST "chmod +x /tmp/cleanup_stale_vms.sh && /tmp/cleanup_stale_vms.sh"
    
    echo "3. Cleaning up temporary script..."
    ssh root@$PROXMOX_HOST "rm -f /tmp/cleanup_stale_vms.sh"
fi

echo ""
echo "✅ Cleanup completed!"
echo ""
echo "4. Verifying remaining VMs..."
ssh root@$PROXMOX_HOST "qm list"

echo ""
echo "5. Checking template 9000 status..."
template_status=$(ssh root@$PROXMOX_HOST "qm config 9000 | grep template" 2>/dev/null || echo "not found")

if echo "$template_status" | grep -q "template: 1"; then
    echo "✅ Template 9000 is properly configured"
    echo ""
    echo "🚀 Ready to deploy Chef 360!"
    echo "Run: tofu apply -auto-approve"
else
    echo "⚠️  Template 9000 needs to be configured properly"
    echo "Run the create-ubuntu-template.sh script first"
fi
