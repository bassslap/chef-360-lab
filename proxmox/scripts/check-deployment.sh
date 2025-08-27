#!/bin/bash

# Complete deployment status checker
# This script waits for VMs to get IP addresses and then refreshes Terraform state

set -e

echo "🚀 Chef 360 Deployment Status Checker"
echo "======================================"
echo ""

# Check if VMs are running first
echo "1️⃣  Checking VM status..."
ssh root@192.168.220.200 'qm list' | grep -E "(chef360|node|workstation)" || {
    echo "❌ No Chef 360 VMs found. Please run the deployment first."
    exit 1
}

echo "✅ VMs found and appear to be created"
echo ""

# Wait for IP addresses
echo "2️⃣  Waiting for DHCP IP assignment..."
./scripts/wait-for-ips.sh

# Refresh Terraform state
echo "3️⃣  Refreshing Terraform state..."
if [[ -f "terraform.tfvars.test" ]]; then
    echo "Using terraform.tfvars.test configuration..."
    tofu refresh -var-file="terraform.tfvars.test"
else
    echo "Using default terraform.tfvars configuration..."
    tofu refresh
fi

# Show final outputs
echo ""
echo "4️⃣  Final deployment information:"
echo "=================================="
tofu output

echo ""
echo "🎉 Deployment Status Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. SSH to chef360-linux-01 to check Chef 360 installation progress:"
echo "   ssh ubuntu@<chef360-ip>"
echo "   sudo tail -f /home/ubuntu/chef-360-install.log"
echo ""
echo "2. Chef 360 services will be available at:"
echo "   - Dashboard: http://<chef360-ip>:30000"
echo "   - Platform: http://<chef360-ip>:31000" 
echo "   - Mailpit: http://<chef360-ip>:31101"
echo ""
echo "3. Chef 360 installation can take 10-15 minutes after VM boot"
