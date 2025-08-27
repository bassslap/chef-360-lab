#!/bin/bash

PROXMOX_HOST="192.168.220.200"
GATEWAY="192.168.220.1"
BASE_NETWORK="192.168.220"

echo "=== VM Network Fix Script ==="
echo "Proxmox Host: $PROXMOX_HOST"
echo "Gateway: $GATEWAY"
echo "Base Network: $BASE_NETWORK"
echo ""

# First, let's check if we can connect to Proxmox
echo "Testing connection to Proxmox..."
if ssh -o ConnectTimeout=5 root@$PROXMOX_HOST 'echo "Connected successfully"'; then
    echo "✓ SSH connection to Proxmox successful"
else
    echo "✗ Cannot connect to Proxmox host"
    echo "Please check:"
    echo "  1. SSH key is set up for root@$PROXMOX_HOST"
    echo "  2. Proxmox host is reachable"
    exit 1
fi

echo ""
echo "Checking current VM status..."
ssh root@$PROXMOX_HOST 'qm list'

echo ""
echo "Fixing VM networking with static IPs (last octet = VM ID)..."

VM_IDS=(101 102 103 104)

for vm_id in "${VM_IDS[@]}"; do
    echo "=== Processing VM $vm_id ==="
    
    # Check if VM exists
    if ssh root@$PROXMOX_HOST "qm status $vm_id >/dev/null 2>&1"; then
        echo "VM $vm_id exists"
        
        ip_address="$BASE_NETWORK.$vm_id"
        ip_config="$ip_address/23,gw=$GATEWAY"
        
        echo "Configuring VM $vm_id with IP: $ip_address"
        
        # Stop VM
        echo "Stopping VM $vm_id..."
        ssh root@$PROXMOX_HOST "qm shutdown $vm_id --timeout 30 || qm stop $vm_id"
        sleep 5
        
        # Configure static IP via cloud-init
        echo "Setting IP configuration: $ip_config"
        ssh root@$PROXMOX_HOST "qm set $vm_id --ipconfig0 ip=$ip_config"
        
        # Start VM
        echo "Starting VM $vm_id..."
        ssh root@$PROXMOX_HOST "qm start $vm_id"
        
        echo "VM $vm_id configured and started"
    else
        echo "VM $vm_id does not exist"
    fi
    echo ""
    sleep 2
done

echo "All VMs processed. Configuration summary:"
echo "  VM 101 (chef360-linux-01)     → 192.168.220.101"
echo "  VM 102 (workstation-linux-01) → 192.168.220.102"
echo "  VM 103 (node-linux-01)        → 192.168.220.103"
echo "  VM 104 (node-linux-02)        → 192.168.220.104"

echo ""
echo "Waiting 60 seconds for VMs to fully boot..."
sleep 60

# Test connectivity
echo "Testing connectivity..."
for vm_id in "${VM_IDS[@]}"; do
    ip_address="$BASE_NETWORK.$vm_id"
    echo -n "Testing VM $vm_id at $ip_address... "
    if ping -c 2 -W 3 $ip_address >/dev/null 2>&1; then
        echo "✓ Reachable"
    else
        echo "✗ Not reachable yet"
    fi
done

echo ""
echo "=== Access Information ==="
echo "Chef 360 Dashboard: http://192.168.220.101:30000"
echo "Chef 360 Platform:  http://192.168.220.101:31000"
echo "Mailpit:           http://192.168.220.101:31101"
echo ""
echo "SSH Access: ssh ubuntu@192.168.220.10X"
echo "Password: C1oudistheb3$t!"
