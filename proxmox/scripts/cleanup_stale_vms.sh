#!/bin/bash
echo "Cleaning up stale VMs on Proxmox..."

# List of stale VM IDs - these are the Chef 360 VMs that failed to deploy properly
STALE_VMS="102 103 104 105 106 107 108"

# Note: VM 100 (eve) is left out as it might be a legitimate VM
# Note: VM 201 (pihole) is running and left alone
# Note: VM 9000 is the template and should be kept

echo "Will clean up these stale Chef 360 VMs: $STALE_VMS"
echo ""

for vmid in $STALE_VMS; do
    echo "Cleaning up VM $vmid..."
    qm stop $vmid --skiplock 2>/dev/null || true
    sleep 1
    qm destroy $vmid --purge --skiplock 2>/dev/null || true
    echo "VM $vmid cleanup completed"
done

echo ""
echo "Stale VM cleanup finished!"
echo ""
echo "Remaining VMs should be:"
echo "- 201 (pihole) - kept as it's running"
echo "- 9000 (ubuntu-22.04-template) - kept as it's the template" 
echo "- 100 (eve) - review manually if needed"
