#!/bin/bash

# Pre-Terraform Setup Script
# Checks IP availability and VM ID conflicts before deployment

set -e  # Exit on any error

# Configuration
PROXMOX_HOST="192.168.220.200"
BASE_NETWORK="192.168.220"
GATEWAY="192.168.220.1"

echo "=== Pre-Terraform Setup Check ==="
echo "Checking environment before Chef 360 deployment..."
echo ""

# SSH key setup for passwordless access
setup_ssh_keys() {
    echo "Setting up SSH key access to avoid password prompts..."
    
    # Check if SSH key exists
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    # Test if we already have passwordless access
    if ssh -o BatchMode=yes -o ConnectTimeout=5 root@$PROXMOX_HOST 'echo "test"' >/dev/null 2>&1; then
        echo "   ✓ SSH key access already configured"
        return 0
    fi
    
    # Copy SSH key to Proxmox host (this may require password once)
    echo "Installing SSH key on Proxmox host (will require password this ONE time only)..."
    if ssh-copy-id -o ConnectTimeout=10 root@$PROXMOX_HOST; then
        echo "   ✓ SSH key installed successfully - no more passwords needed!"
        echo "   All future operations will be passwordless!"
    else
        echo "   ⚠ SSH key installation failed. Will continue with password prompts."
    fi
}

# Function to check if IP is pingable
check_ip_available() {
    local ip=$1
    if timeout 3 ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        return 1  # IP is in use
    else
        return 0  # IP is available
    fi
}

# Function to find next available IP starting from given base
find_next_available_ip() {
    local start_ip=$1
    local max_tries=10
    
    # Extract the last octet
    local base_num=${start_ip##*.}
    local network_base=${start_ip%.*}
    
    for ((i=0; i<max_tries; i++)); do
        local test_ip="$network_base.$((base_num + i))"
        echo -n "     Trying $test_ip... "
        if check_ip_available "$test_ip"; then
            echo "✓ Available"
            echo "$test_ip"
            return 0
        else
            echo "✗ In use"
        fi
    done
    
    echo "     ✗ No available IP found in range"
    return 1
}

# Function to check if VM ID exists on Proxmox (try passwordless first)
check_vm_id_available() {
    local vm_id=$1
    # Try passwordless first, then with password
    if ssh -o BatchMode=yes -o ConnectTimeout=5 root@$PROXMOX_HOST "qm status $vm_id >/dev/null 2>&1" 2>/dev/null; then
        return 1  # VM ID exists
    elif ssh -o ConnectTimeout=5 root@$PROXMOX_HOST "qm status $vm_id >/dev/null 2>&1" 2>/dev/null; then
        return 1  # VM ID exists
    else
        return 0  # VM ID available
    fi
}

# Setup SSH keys first
setup_ssh_keys

# Determine if we have passwordless access
echo ""
echo "Testing SSH access method..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 root@$PROXMOX_HOST 'echo "test"' >/dev/null 2>&1; then
    echo "   ✓ Passwordless SSH access confirmed"
    SSH_CMD="ssh -o BatchMode=yes root@$PROXMOX_HOST"
    PASSWORDLESS=true
else
    echo "   ⚠ Using password authentication"
    SSH_CMD="ssh root@$PROXMOX_HOST"
    PASSWORDLESS=false
fi

# 1. Test Proxmox connectivity
echo ""
echo "1. Testing Proxmox connectivity..."
if $SSH_CMD 'echo "Connection successful"' >/dev/null 2>&1; then
    if [ "$PASSWORDLESS" = true ]; then
        echo "   ✓ SSH connection to Proxmox ($PROXMOX_HOST) successful (passwordless)"
    else
        echo "   ✓ SSH connection to Proxmox ($PROXMOX_HOST) successful (with password)"
    fi
else
    echo "   ✗ Cannot connect to Proxmox host ($PROXMOX_HOST)"
    exit 1
fi

# 2. Check template availability
echo ""
echo "2. Checking template availability..."
TEMPLATE_ID=9000
if $SSH_CMD "qm status $TEMPLATE_ID >/dev/null 2>&1"; then
    template_config=$($SSH_CMD "qm config $TEMPLATE_ID | grep template" || echo "")
    if [[ -n "$template_config" ]]; then
        echo "   ✓ Template VM $TEMPLATE_ID exists and is properly configured"
    else
        echo "   ⚠ VM $TEMPLATE_ID exists but is not marked as template"
        echo "   Converting to template..."
        $SSH_CMD "qm template $TEMPLATE_ID"
        echo "   ✓ VM $TEMPLATE_ID converted to template"
    fi
else
    echo "   ✗ Template VM $TEMPLATE_ID does not exist"
    echo "   Please create the Ubuntu template first"
    exit 1
fi

# 3. Check VM ID availability (Updated to match Terraform: 100, 101, 102, 103)
echo ""
echo "3. Checking VM ID availability..."
conflicts_found=false

# Check each VM ID individually - Updated to start at 100
for vm_id in 100 101 102 103; do
    case $vm_id in
        100) vm_name="chef360-01" ;;
        101) vm_name="chef360-workstation-01" ;;
        102) vm_name="chef360-node-01" ;;
        103) vm_name="chef360-node-02" ;;
    esac
    
    if check_vm_id_available $vm_id; then
        echo "   ✓ VM ID $vm_id available for $vm_name"
    else
        echo "   ✗ VM ID $vm_id already exists (conflicts with $vm_name)"
        conflicts_found=true
    fi
done

if $conflicts_found; then
    echo ""
    echo "   VM ID conflicts detected. Options:"
    echo "   1. Remove conflicting VMs: ./scripts/cleanup-conflicting-vms.sh"
    echo "   2. Use different VM IDs in terraform.tfvars"
    exit 1
fi

# 4. Check IP address availability with auto-increment from .121-.124
echo ""
echo "4. Checking IP address availability (starting from .121-.124 range)..."

# Initialize variables for IP assignments (Updated variable names)
VM_100_IP=""  # Chef 360
VM_101_IP=""  # Workstation
VM_102_IP=""  # Node 1
VM_103_IP=""  # Node 2

# Check VM 100 (Chef 360) - start from .121
echo "   Checking for chef360-01..."
echo -n "     Trying 192.168.220.121... "
if check_ip_available "192.168.220.121"; then
    echo "✓ Available"
    VM_100_IP="192.168.220.121"
else
    echo "✗ In use, finding alternative..."
    VM_100_IP=$(find_next_available_ip "192.168.220.121")
    if [ $? -eq 0 ]; then
        echo "     → Assigned $VM_100_IP to chef360-01"
    else
        echo "     ✗ Could not find available IP for chef360-01"
        exit 1
    fi
fi

# Check VM 101 (Workstation) - start from .122
echo "   Checking for chef360-workstation-01..."
echo -n "     Trying 192.168.220.122... "
if check_ip_available "192.168.220.122"; then
    echo "✓ Available"
    VM_101_IP="192.168.220.122"
else
    echo "✗ In use, finding alternative..."
    VM_101_IP=$(find_next_available_ip "192.168.220.122")
    if [ $? -eq 0 ]; then
        echo "     → Assigned $VM_101_IP to chef360-workstation-01"
    else
        echo "     ✗ Could not find available IP for chef360-workstation-01"
        exit 1
    fi
fi

# Check VM 102 (Node 1) - start from .123
echo "   Checking for chef360-node-01..."
echo -n "     Trying 192.168.220.123... "
if check_ip_available "192.168.220.123"; then
    echo "✓ Available"
    VM_102_IP="192.168.220.123"
else
    echo "✗ In use, finding alternative..."
    VM_102_IP=$(find_next_available_ip "192.168.220.123")
    if [ $? -eq 0 ]; then
        echo "     → Assigned $VM_102_IP to chef360-node-01"
    else
        echo "     ✗ Could not find available IP for chef360-node-01"
        exit 1
    fi
fi

# Check VM 103 (Node 2) - start from .124
echo "   Checking for chef360-node-02..."
echo -n "     Trying 192.168.220.124... "
if check_ip_available "192.168.220.124"; then
    echo "✓ Available"
    VM_103_IP="192.168.220.124"
else
    echo "✗ In use, finding alternative..."
    VM_103_IP=$(find_next_available_ip "192.168.220.124")
    if [ $? -eq 0 ]; then
        echo "     → Assigned $VM_103_IP to chef360-node-02"
    else
        echo "     ✗ Could not find available IP for chef360-node-02"
        exit 1
    fi
fi

# 5. Check storage availability
echo ""
echo "5. Checking storage availability..."
STORAGE="proxmox_storage_1"  # Updated to match your working datastore
storage_info=$($SSH_CMD "pvesm status -storage $STORAGE 2>/dev/null" || echo "error")
if [[ "$storage_info" != "error" ]]; then
    echo "   ✓ Storage '$STORAGE' is available"
else
    echo "   ✗ Storage '$STORAGE' not found or not accessible"
    echo "   Available storage pools:"
    $SSH_CMD "pvesm status" | tail -n +2
    exit 1
fi

# 6. Check network bridge
echo ""
echo "6. Checking network bridge..."
BRIDGE="vmbr0"
if $SSH_CMD "ip link show $BRIDGE >/dev/null 2>&1"; then
    echo "   ✓ Network bridge '$BRIDGE' exists"
else
    echo "   ✗ Network bridge '$BRIDGE' not found"
    echo "   Available bridges:"
    $SSH_CMD "ip link show type bridge"
    exit 1
fi

# 7. Generate deployment summary
echo ""
echo "=== Deployment Summary ==="
echo "Environment checks completed successfully!"
echo ""
echo "Final IP assignments:"
echo "  VM 100: chef360-01 → $VM_100_IP"
echo "  VM 101: chef360-workstation-01 → $VM_101_IP"
echo "  VM 102: chef360-node-01 → $VM_102_IP"
echo "  VM 103: chef360-node-02 → $VM_103_IP"
echo ""
echo "Infrastructure specs:"
echo "  Chef 360:   VM 100, $VM_100_IP, 8 cores, 48GB RAM, 750GB disk"
echo "  Workstation: VM 101, $VM_101_IP, 2 cores, 4GB RAM, 40GB disk"
echo "  Linux Nodes: VM 102-103, $VM_102_IP-$VM_103_IP, 2 cores, 4GB RAM, 20GB disk each"
echo ""

# Save IP assignments for use by deploy script (Updated variable names)
echo "# Auto-generated IP assignments" > /tmp/chef360_ip_assignments.txt
echo "CHEF360_IP=$VM_100_IP" >> /tmp/chef360_ip_assignments.txt
echo "WORKSTATION_IP=$VM_101_IP" >> /tmp/chef360_ip_assignments.txt
echo "NODE_1_IP=$VM_102_IP" >> /tmp/chef360_ip_assignments.txt
echo "NODE_2_IP=$VM_103_IP" >> /tmp/chef360_ip_assignments.txt

# Also keep old format for compatibility
echo "VM_100_IP=$VM_100_IP" >> /tmp/chef360_ip_assignments.txt
echo "VM_101_IP=$VM_101_IP" >> /tmp/chef360_ip_assignments.txt
echo "VM_102_IP=$VM_102_IP" >> /tmp/chef360_ip_assignments.txt
echo "VM_103_IP=$VM_103_IP" >> /tmp/chef360_ip_assignments.txt

echo "✓ Ready for Terraform deployment!"
echo "✓ IP assignments saved to /tmp/chef360_ip_assignments.txt"

if [ "$PASSWORDLESS" = false ]; then
    echo ""
    echo "💡 To avoid future password prompts, run:"
    echo "   ssh-copy-id root@$PROXMOX_HOST"
fi