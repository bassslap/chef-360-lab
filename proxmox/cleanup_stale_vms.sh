#!/bin/bash
echo "Cleaning up VMs by tags on Proxmox..."

# Proxmox server details
PROXMOX_HOST="192.168.220.200"
PROXMOX_USER="root"

# Target tags to clean up (comma-separated)
TARGET_TAGS="chef360,chef,lab"

# Check for non-interactive flag
NON_INTERACTIVE=${1:-false}

echo "Looking for VMs with tags: $TARGET_TAGS"

# Function to check if VM has target tags
vm_has_target_tags() {
    local vmid=$1
    local vm_tags=$(qm config $vmid 2>/dev/null | grep "^tags:" | cut -d' ' -f2-)
    
    if [ -z "$vm_tags" ]; then
        return 1  # No tags found
    fi
    
    # Check if any target tag is present in VM tags
    IFS=',' read -ra TAG_ARRAY <<< "$TARGET_TAGS"
    for target_tag in "${TAG_ARRAY[@]}"; do
        if echo "$vm_tags" | grep -q "$target_tag"; then
            return 0  # Found matching tag
        fi
    done
    
    return 1  # No matching tags
}

# Get all VMs and filter by tags
echo "Scanning all VMs for matching tags..."
VMS_TO_CLEANUP=()

# Get list of all VM IDs
ALL_VMS=$(qm list | tail -n +2 | awk '{print $1}')

for vmid in $ALL_VMS; do
    if vm_has_target_tags $vmid; then
        VM_NAME=$(qm config $vmid 2>/dev/null | grep "^name:" | cut -d' ' -f2- || echo "unknown")
        VM_TAGS=$(qm config $vmid 2>/dev/null | grep "^tags:" | cut -d' ' -f2- || echo "none")
        echo "  Found VM $vmid: $VM_NAME (tags: $VM_TAGS)"
        VMS_TO_CLEANUP+=($vmid)
    fi
done

if [ ${#VMS_TO_CLEANUP[@]} -eq 0 ]; then
    echo "No VMs found with target tags: $TARGET_TAGS"
    exit 0
fi

echo ""
echo "Found ${#VMS_TO_CLEANUP[@]} VMs to clean up:"
for vmid in "${VMS_TO_CLEANUP[@]}"; do
    VM_NAME=$(qm config $vmid 2>/dev/null | grep "^name:" | cut -d' ' -f2- || echo "unknown")
    echo "  - VM $vmid: $VM_NAME"
done

echo ""
# Non-interactive mode or interactive confirmation
if [ "$NON_INTERACTIVE" = "true" ] || [ "$NON_INTERACTIVE" = "--yes" ]; then
    echo "Non-interactive mode: Proceeding with cleanup..."
    REPLY="yes"
else
    echo "Interactive mode: Waiting for confirmation..."
    read -t 30 -p "Are you sure you want to delete these VMs? (yes/no): " -r || {
        echo ""
        echo "Timeout or no input received. Cleanup cancelled."
        exit 1
    }
fi

if [[ ! $REPLY == "yes" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Cleaning up tagged VMs..."

for vmid in "${VMS_TO_CLEANUP[@]}"; do
    echo "Cleaning up VM $vmid..."
    VM_NAME=$(qm config $vmid 2>/dev/null | grep "^name:" | cut -d' ' -f2- || echo "unknown")
    echo "  VM Name: $VM_NAME"
    qm stop $vmid --skiplock || true
    sleep 2
    qm destroy $vmid --purge --skiplock || true
    echo "  VM $vmid ($VM_NAME) cleanup completed"
done

echo ""
echo "Tagged VM cleanup finished!"