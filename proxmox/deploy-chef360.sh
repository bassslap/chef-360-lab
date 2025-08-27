#!/bin/bash
# filepath: /Users/bphillip/CHEF_360_CORE/chef-360-core/proxmox/deploy-chef360.sh

# Complete Chef 360 deployment script with pre-checks

set -e

echo "=== Chef 360 Proxmox Deployment ==="
echo "Complete deployment with pre-checks and validation"
echo ""

# 1. Pre-deployment checks
echo "Step 1: Running pre-deployment checks..."
./scripts/pre-terraform-check.sh

if [ $? -ne 0 ]; then
    echo "Pre-deployment checks failed. Please resolve issues before continuing."
    exit 1
fi

# Extract IPs dynamically from terraform.tfvars
echo "Step 2: Extracting IP addresses from terraform.tfvars..."

# Extract Chef 360 IP (VM ID 100)
CHEF360_IP=$(grep -A 20 "chef360 = {" terraform.tfvars | grep "ip_address" | sed 's/.*= *"\([^"]*\)".*/\1/')

# Extract Workstation IP (VM ID 101)
WORKSTATION_IP=$(grep -A 20 "workstation = {" terraform.tfvars | grep "ip_address" | sed 's/.*= *"\([^"]*\)".*/\1/')

# Extract Proxmox host IP for VM status checks
PROXMOX_IP=$(grep -A 20 "proxmox = {" terraform.tfvars | grep "endpoint" | sed 's/.*https:\/\/\([^:]*\):.*/\1/')

# Extract node configuration dynamically
NODE_START_IP=$(grep -A 10 "linux_nodes = {" terraform.tfvars | grep "ip_start" | sed 's/.*= *"\([^"]*\)".*/\1/')
NODE_COUNT=$(grep -A 10 "linux_nodes = {" terraform.tfvars | grep "count" | sed 's/.*= *\([0-9]*\).*/\1/')

# Calculate node IPs and VM IDs dynamically
NODE_IPS=()
NODE_VM_IDS=()
if [ -n "$NODE_START_IP" ] && [ -n "$NODE_COUNT" ]; then
    IFS='.' read -ra IP_PARTS <<< "$NODE_START_IP"
    BASE_IP="${IP_PARTS[0]}.${IP_PARTS[1]}.${IP_PARTS[2]}"
    START_NUM="${IP_PARTS[3]}"
    
    # Build arrays for node IPs and VM IDs
    for ((i=0; i<NODE_COUNT; i++)); do
        NODE_IPS+=("$BASE_IP.$((START_NUM + i))")
        NODE_VM_IDS+=("$((102 + i))")  # VM IDs start at 102
    done
else
    echo "Warning: Could not extract node configuration, using defaults"
    NODE_COUNT=2
    NODE_IPS=("192.168.220.123" "192.168.220.124")
    NODE_VM_IDS=("102" "103")
fi

# Build VM ID pattern for grep dynamically
VM_ID_PATTERN="100|101"  # Chef360 and Workstation
for vm_id in "${NODE_VM_IDS[@]}"; do
    VM_ID_PATTERN="$VM_ID_PATTERN|$vm_id"
done

echo "Extracted configuration:"
echo "  Chef 360 (VM 100): $CHEF360_IP"
echo "  Workstation (VM 101): $WORKSTATION_IP"
echo "  Proxmox Host: $PROXMOX_IP"
echo "  Node Count: $NODE_COUNT"
echo "  Node IPs: ${NODE_IPS[*]}"
echo "  Node VM IDs: ${NODE_VM_IDS[*]}"
echo "  VM ID Pattern: ($VM_ID_PATTERN)"

# Save IP assignments for other scripts
cat > /tmp/chef360_ip_assignments.txt << EOF
CHEF360_IP="$CHEF360_IP"
WORKSTATION_IP="$WORKSTATION_IP"
PROXMOX_IP="$PROXMOX_IP"
NODE_COUNT="$NODE_COUNT"
NODE_IPS=(${NODE_IPS[*]})
NODE_VM_IDS=(${NODE_VM_IDS[*]})
EOF

echo ""
echo "Step 3: Init/Planning Terraform deployment..."
tofu init
tofu plan

echo ""
read -p "Proceed with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled by user."
    exit 0
fi

echo ""
echo "Step 4: Deploying infrastructure..."
tofu apply -auto-approve

echo ""
echo "Step 5: Extracting deployment information..."
    
# Extract FQDN from Terraform output
CHEF_FQDN=$(tofu output -json access_info | jq -r '.chef_platform_fqdn' 2>/dev/null || echo "chef360.lab.local")
    
echo "Using FQDN: $CHEF_FQDN"

if [ $? -eq 0 ]; then
    echo ""
    echo "Step 6: Verifying deployment..."
    sleep 30  # Wait for VMs to start
    
    # Check VM status using dynamic VM ID pattern
    # echo "Checking VM status for pattern: ($VM_ID_PATTERN)"
    # if ssh -o BatchMode=yes -o ConnectTimeout=5 root@$PROXMOX_IP "qm list | grep -E '($VM_ID_PATTERN)'" 2>/dev/null; then
    #     echo "Using passwordless SSH to Proxmox"
    # else
    #     ssh root@$PROXMOX_IP "qm list | grep -E '($VM_ID_PATTERN)'"
    # fi
    
    echo ""
    echo "Step 7: Testing connectivity..."
    
    # Test Chef 360
    echo -n "Testing Chef 360 (VM 100: $CHEF360_IP)... "
    if timeout 5 ping -c 2 -W 3 $CHEF360_IP >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗ (may still be booting)"
    fi
    
    # Test Workstation  
    echo -n "Testing Workstation (VM 101: $WORKSTATION_IP)... "
    if timeout 5 ping -c 2 -W 3 $WORKSTATION_IP >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗ (may still be booting)"
    fi
    
    # Test all nodes dynamically using loop
    for i in "${!NODE_IPS[@]}"; do
        node_ip="${NODE_IPS[$i]}"
        node_vm_id="${NODE_VM_IDS[$i]}"
        node_num=$((i + 1))
        echo -n "Testing Node $node_num (VM $node_vm_id: $node_ip)... "
        if timeout 5 ping -c 2 -W 3 $node_ip >/dev/null 2>&1; then
            echo "✓"
        else
            echo "✗ (may still be booting)"
        fi
    done
    
    echo ""
    echo "=== Deployment Complete! ==="
    echo ""
    echo "🎉 Chef 360 infrastructure deployed successfully!"
    echo ""
    echo "Access Information:"
    echo "  Chef 360 Dashboard: http://$CHEF360_IP:30000"
    echo "  Chef 360 Platform:  http://$CHEF360_IP:31000"
    echo "  Mailpit:           http://$CHEF360_IP:31101"
    echo ""
    echo "Access via FQDN (add to /etc/hosts):"
    echo "  Chef 360 Dashboard: http://$CHEF_FQDN:30000"
    echo "  Chef 360 Platform:  http://$CHEF_FQDN:31000"
    echo "  Mailpit:           http://$CHEF_FQDN:31101"
    echo ""
    echo "Add to /etc/hosts:"
    echo "  $CHEF360_IP $CHEF_FQDN"
    echo ""
    echo "SSH Access:"
    echo "  ssh ubuntu@$CHEF360_IP      # Chef 360 server (VM 100)"
    echo "  ssh ubuntu@$WORKSTATION_IP  # Workstation (VM 101)"
    
    # Dynamic SSH access for nodes using loop
    for i in "${!NODE_IPS[@]}"; do
        node_ip="${NODE_IPS[$i]}"
        node_vm_id="${NODE_VM_IDS[$i]}"
        node_num=$((i + 1))
        echo "  ssh ubuntu@$node_ip      # Node $node_num (VM $node_vm_id)"
    done
    
    echo ""
    echo "Password: ubuntu123!"
    echo ""
    echo "SSL Certificates:"
    echo "  Private Key: ~/tmp/$CHEF_FQDN.key.pem"
    echo "  Certificate: ~/tmp/$CHEF_FQDN.chain.pem"
    echo ""
    echo "Note: Chef 360 installation may take 10-15 minutes after VM boot."
    echo "Check installation progress: ssh ubuntu@$CHEF360_IP 'sudo journalctl -f'"
    
else
    echo "Deployment failed. Check the error messages above."
    exit 1
fi