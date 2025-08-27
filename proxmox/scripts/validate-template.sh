#!/bin/bash

echo "=== Proxmox Template Validation ==="
echo ""

PROXMOX_HOST="192.168.220.200"
API_TOKEN="terraform@pve!terraform=a1c550c3-c05d-4e2f-b59f-72df158f86bb"
NODE="proxmox"

echo "1. Checking template 9000 configuration..."

# Check template VM configuration
template_config=$(curl -k -s -H "Authorization: PVEAPIToken=$API_TOKEN" \
    "https://$PROXMOX_HOST:8006/api2/json/nodes/$NODE/qemu/9000/config" 2>/dev/null)

if echo "$template_config" | jq -e '.data' >/dev/null 2>&1; then
    echo "✅ Template 9000 exists and is accessible"
    
    # Check if it's actually a template
    is_template=$(echo "$template_config" | jq -r '.data.template // false' 2>/dev/null)
    echo "   Template status: $is_template"
    
    # Check disk configuration
    echo "   Checking disk configuration..."
    echo "$template_config" | jq -r '.data | to_entries[] | select(.key | startswith("scsi") or startswith("virtio") or startswith("ide") or startswith("sata")) | "\(.key): \(.value)"' 2>/dev/null || echo "   No disk configuration found"
    
    # Check cloud-init configuration
    echo "   Checking cloud-init configuration..."
    echo "$template_config" | jq -r '.data | to_entries[] | select(.key == "ide2" or .key == "cloudinit") | "\(.key): \(.value)"' 2>/dev/null || echo "   No cloud-init disk found"
    
    if [ "$is_template" = "1" ] || [ "$is_template" = "true" ]; then
        echo "✅ Template is properly configured"
    else
        echo "❌ VM 9000 exists but is not marked as a template"
        echo "   Run: ssh root@$PROXMOX_HOST 'qm template 9000'"
    fi
else
    echo "❌ Template 9000 is not accessible or doesn't exist"
    echo "   Error response: $template_config"
fi

echo ""
echo "2. Creating a simple test VM to validate template..."

# Create a simple test VM that just clones the template without complex configuration
test_vm_id="999"

echo "   Creating test VM $test_vm_id..."

# First, check if test VM already exists and remove it
existing_vm=$(curl -k -s -H "Authorization: PVEAPIToken=$API_TOKEN" \
    "https://$PROXMOX_HOST:8006/api2/json/nodes/$NODE/qemu/$test_vm_id" 2>/dev/null)

if echo "$existing_vm" | jq -e '.data' >/dev/null 2>&1; then
    echo "   Test VM $test_vm_id already exists, removing it..."
    curl -k -s -X DELETE -H "Authorization: PVEAPIToken=$API_TOKEN" \
        "https://$PROXMOX_HOST:8006/api2/json/nodes/$NODE/qemu/$test_vm_id" >/dev/null 2>&1
    sleep 2
fi

echo ""
echo "3. Manual test VM creation commands:"
echo "   Run these on your Proxmox host to test the template:"
echo ""

cat << 'EOF'
# Test template 9000 by creating a simple clone
qm clone 9000 999 --name test-template-clone --full

# Check if clone was successful
qm list | grep 999

# Check the cloned VM configuration
qm config 999

# If successful, clean up the test VM
qm destroy 999 --purge

# If the clone fails, the template may need to be recreated
EOF

echo ""
echo "4. Template troubleshooting commands:"
echo ""

cat << 'EOF'
# Check template disk size and format
qm config 9000 | grep -E "(scsi|virtio|ide|sata)"

# Verify template status
qm config 9000 | grep template

# Check if cloud-init is properly configured
qm config 9000 | grep ide2

# If template is corrupted, recreate it:
# 1. Remove existing template
qm destroy 9000 --purge

# 2. Recreate using the cloud image method
cd /var/lib/vz/template/iso
wget -O ubuntu-22.04-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
qm create 9000 --name ubuntu-22.04-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm disk import 9000 ubuntu-22.04-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --scsihw virtio-scsi-pci --boot order=scsi0
qm set 9000 --agent enabled=1
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm template 9000
EOF

echo ""
echo "5. If template is working, the issue might be with the BPG provider disk resizing."
echo "   Try deploying with smaller disk sizes first, then resize after deployment."
