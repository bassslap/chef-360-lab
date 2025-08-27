#!/bin/bash

# Script to clean up stale/orphaned VMs in Proxmox
set -e

# Configuration
PROXMOX_HOST="192.168.220.200"
API_TOKEN="terraform@pve!terraform=a1c550c3-c05d-4e2f-b59f-72df158f86bb"
NODE="proxmox"

echo "=== Proxmox VM Cleanup Tool ==="
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

echo "1. Listing all VMs on node '$NODE'..."
echo ""

# Get all VMs
vm_list=$(api_call GET "/nodes/$NODE/qemu" 2>/dev/null || echo '{"data":[]}')

if [ "$vm_list" = "" ] || ! echo "$vm_list" | jq -e '.data' >/dev/null 2>&1; then
    echo "❌ Could not retrieve VM list via API. Trying SSH approach..."
    echo ""
    echo "Please run these commands on your Proxmox host:"
    echo ""
    
    cat << 'EOF'
# List all VMs
echo "=== All VMs ==="
qm list

# List only running VMs
echo ""
echo "=== Running VMs ==="
qm list | grep running

# List stopped VMs
echo ""
echo "=== Stopped VMs ==="
qm list | grep stopped

# List VMs that might be stuck
echo ""
echo "=== Potentially stuck VMs ==="
qm list | grep -E "(unknown|locked)"

# To stop and destroy specific VMs (replace VMID with actual ID):
echo ""
echo "=== To remove specific VMs ==="
echo "qm stop VMID --skiplock || true"
echo "qm destroy VMID --purge --skiplock || true"

# To remove all non-template VMs (DANGEROUS - be careful):
echo ""
echo "=== To remove ALL non-template VMs (use with caution) ==="
echo "for vmid in \$(qm list | grep -v 'template' | awk 'NR>1 {print \$1}'); do"
echo "    echo \"Removing VM \$vmid...\""
echo "    qm stop \$vmid --skiplock || true"
echo "    qm destroy \$vmid --purge --skiplock || true"
echo "done"
EOF
    
    exit 0
fi

echo "Found VMs:"
echo "$vm_list" | jq -r '.data[] | "\(.vmid) - \(.name) - \(.status) - Template: \(.template // "no")"' 2>/dev/null || {
    echo "Could not parse VM data. Raw response:"
    echo "$vm_list"
    exit 1
}

echo ""
echo "2. Identifying potentially problematic VMs..."

# Get VMs that are not templates and might be stale
stale_vms=$(echo "$vm_list" | jq -r '.data[] | select(.template != 1 and .template != true) | select(.status != "running") | .vmid' 2>/dev/null || echo "")

if [ -z "$stale_vms" ]; then
    echo "✅ No stale VMs found."
else
    echo "Found potentially stale VMs:"
    for vmid in $stale_vms; do
        vm_info=$(echo "$vm_list" | jq -r ".data[] | select(.vmid == $vmid) | \"\(.vmid) - \(.name) - \(.status)\"" 2>/dev/null)
        echo "  $vm_info"
    done
    
    echo ""
    echo "3. VM cleanup options:"
    echo ""
    
    # Create individual cleanup commands
    for vmid in $stale_vms; do
        echo "# Clean up VM $vmid:"
        echo "ssh root@$PROXMOX_HOST 'qm stop $vmid --skiplock || true && qm destroy $vmid --purge --skiplock || true'"
        echo ""
    done
    
    # Create a bulk cleanup script
    cat > cleanup_stale_vms.sh << 'CLEANUP_SCRIPT'
#!/bin/bash
echo "Cleaning up stale VMs on Proxmox..."

# List of stale VM IDs (edit this list as needed)
STALE_VMS="STALE_VM_IDS_PLACEHOLDER"

for vmid in $STALE_VMS; do
    echo "Cleaning up VM $vmid..."
    qm stop $vmid --skiplock || true
    sleep 2
    qm destroy $vmid --purge --skiplock || true
    echo "VM $vmid cleanup completed"
done

echo "Stale VM cleanup finished!"
CLEANUP_SCRIPT

    # Replace placeholder with actual VM IDs
    sed -i.bak "s/STALE_VM_IDS_PLACEHOLDER/$stale_vms/" cleanup_stale_vms.sh
    chmod +x cleanup_stale_vms.sh
    
    echo "Created cleanup_stale_vms.sh script with stale VM IDs: $stale_vms"
    echo ""
    echo "To run the cleanup:"
    echo "scp cleanup_stale_vms.sh root@$PROXMOX_HOST:/"
    echo "ssh root@$PROXMOX_HOST './cleanup_stale_vms.sh'"
fi

echo ""
echo "4. Check for template VM 9000..."
template_9000=$(echo "$vm_list" | jq -r '.data[] | select(.vmid == 9000)' 2>/dev/null || echo "")

if [ -n "$template_9000" ]; then
    is_template=$(echo "$template_9000" | jq -r '.template // false' 2>/dev/null)
    status=$(echo "$template_9000" | jq -r '.status' 2>/dev/null)
    name=$(echo "$template_9000" | jq -r '.name' 2>/dev/null)
    
    echo "VM 9000 exists: $name (Status: $status, Template: $is_template)"
    
    if [ "$is_template" != "1" ] && [ "$is_template" != "true" ]; then
        echo "⚠️  VM 9000 exists but is NOT a template!"
        echo ""
        echo "To fix this, run on Proxmox host:"
        echo "qm stop 9000 --skiplock || true"
        echo "qm destroy 9000 --purge --skiplock || true"
        echo ""
        echo "Then create a proper template using the create-ubuntu-template.sh script"
    else
        echo "✅ VM 9000 is properly configured as a template"
    fi
else
    echo "VM 9000 does not exist - you'll need to create the template"
fi

echo ""
echo "5. Summary and recommendations:"
echo ""
echo "Next steps:"
echo "1. Run the cleanup commands above to remove stale VMs"
echo "2. Ensure template 9000 exists and is properly configured"
echo "3. Run 'tofu apply' to deploy Chef 360 infrastructure"
echo ""
