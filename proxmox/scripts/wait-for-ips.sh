#!/bin/bash

# Script to wait for VMs to get IP addresses from DHCP
# This script checks the Proxmox VMs until they all have IP addresses assigned

set -e

PROXMOX_HOST="192.168.220.200"
MAX_WAIT_TIME=600  # 10 minutes
CHECK_INTERVAL=30  # 30 seconds
ELAPSED_TIME=0

echo "=== Waiting for VMs to get IP addresses from DHCP ==="
echo "Max wait time: ${MAX_WAIT_TIME} seconds"
echo "Check interval: ${CHECK_INTERVAL} seconds"
echo ""

# VM IDs to check - using simple arrays instead of associative arrays for compatibility
VM_IDS=(101 102 103 104)
VM_NAMES=("chef360-linux-01" "workstation-linux-01" "node-linux-01" "node-linux-02")

get_vm_ip() {
    local vm_id=$1
    local vm_name=$2
    
    # Get VM info from Proxmox
    local vm_info=$(ssh root@${PROXMOX_HOST} "qm config ${vm_id}" 2>/dev/null || echo "")
    local vm_status=$(ssh root@${PROXMOX_HOST} "qm status ${vm_id}" 2>/dev/null | grep -o "status: [a-z]*" | cut -d' ' -f2 || echo "unknown")
    
    if [[ "$vm_status" != "running" ]]; then
        echo "❌ VM ${vm_id} (${vm_name}) is not running (status: ${vm_status})"
        return 1
    fi
    
    # Try to get IP from qemu agent
    local ip_info=$(ssh root@${PROXMOX_HOST} "qm guest cmd ${vm_id} network-get-interfaces" 2>/dev/null || echo "")
    
    if [[ -n "$ip_info" ]]; then
        # Parse JSON to get IP (simplified parsing)
        local ip=$(echo "$ip_info" | grep -o '"ip-address":"[0-9.]*"' | head -1 | cut -d'"' -f4)
        if [[ -n "$ip" && "$ip" != "127.0.0.1" ]]; then
            echo "✅ VM ${vm_id} (${vm_name}): ${ip}"
            return 0
        fi
    fi
    
    # Fallback: try to get IP from DHCP leases or other methods
    local lease_ip=$(ssh root@${PROXMOX_HOST} "grep -h '${vm_name}\\|$(qm config ${vm_id} | grep -o 'net[0-9]*=.*' | grep -o '[0-9A-Fa-f:]\{17\}')' /var/lib/dhcp/dhcpd.leases 2>/dev/null | grep 'lease ' | tail -1 | awk '{print \$2}'" 2>/dev/null || echo "")
    
    if [[ -n "$lease_ip" ]]; then
        echo "✅ VM ${vm_id} (${vm_name}): ${lease_ip} (from DHCP lease)"
        return 0
    fi
    
    echo "⏳ VM ${vm_id} (${vm_name}): Waiting for IP address..."
    return 1
}

check_all_vms() {
    local all_have_ips=true
    
    echo "--- Checking VMs at $(date) ---"
    
    for i in "${!VM_IDS[@]}"; do
        vm_id="${VM_IDS[$i]}"
        vm_name="${VM_NAMES[$i]}"
        if ! get_vm_ip "$vm_id" "$vm_name"; then
            all_have_ips=false
        fi
    done
    
    echo ""
    
    if $all_have_ips; then
        return 0
    else
        return 1
    fi
}

# Main waiting loop
while [[ $ELAPSED_TIME -lt $MAX_WAIT_TIME ]]; do
    if check_all_vms; then
        echo "🎉 All VMs have IP addresses assigned!"
        echo ""
        echo "=== Final IP Summary ==="
        for i in "${!VM_IDS[@]}"; do
            vm_id="${VM_IDS[$i]}"
            vm_name="${VM_NAMES[$i]}"
            get_vm_ip "$vm_id" "$vm_name"
        done
        echo ""
        echo "✅ You can now run 'tofu refresh' to update the Terraform state with these IP addresses"
        exit 0
    fi
    
    echo "Waiting ${CHECK_INTERVAL} seconds before next check... (${ELAPSED_TIME}/${MAX_WAIT_TIME}s elapsed)"
    sleep $CHECK_INTERVAL
    ELAPSED_TIME=$((ELAPSED_TIME + CHECK_INTERVAL))
done

echo "❌ Timeout reached after ${MAX_WAIT_TIME} seconds"
echo "Some VMs may still be getting IP addresses. You can:"
echo "1. Wait a bit longer and run this script again"
echo "2. Check the VMs manually in Proxmox console"
echo "3. Run 'tofu refresh' to update Terraform state"
exit 1
