#!/bin/bash

# Test script to check Proxmox template availability
echo "=== Proxmox Template Check ==="

API_URL="https://192.168.220.200:8006/api2/json"
TOKEN="PVEAPIToken=terraform@pve!terraform=a1c550c3-c05d-4e2f-b59f-72df158f86bb"
NODE="proxmox"

echo "1. Checking if we can access the node..."
node_response=$(curl -k -s -H "Authorization: $TOKEN" "$API_URL/nodes/$NODE")
if echo "$node_response" | grep -q "data"; then
    echo "✅ Node 'proxmox' is accessible"
else
    echo "❌ Cannot access node 'proxmox'"
    echo "Response: $node_response"
    exit 1
fi

echo ""
echo "2. Getting list of all VMs and templates..."
vms_response=$(curl -k -s -H "Authorization: $TOKEN" "$API_URL/nodes/$NODE/qemu")

if echo "$vms_response" | grep -q "data"; then
    echo "✅ Got VM list successfully"
    
    # Check for templates
    echo ""
    echo "3. Looking for templates..."
    templates=$(echo "$vms_response" | jq -r '.data[] | select(.template == 1) | "\(.vmid): \(.name)"' 2>/dev/null)
    
    if [ -n "$templates" ]; then
        echo "Found templates:"
        echo "$templates"
        
        # Check specifically for ubuntu-22.04-cloud
        if echo "$templates" | grep -q "ubuntu-22.04-cloud"; then
            echo "✅ Template 'ubuntu-22.04-cloud' found!"
        else
            echo "❌ Template 'ubuntu-22.04-cloud' NOT found"
            echo ""
            echo "Available templates:"
            echo "$templates"
        fi
    else
        echo "❌ No templates found"
        echo ""
        echo "All VMs:"
        echo "$vms_response" | jq -r '.data[] | "\(.vmid): \(.name) (template: \(.template // false))"' 2>/dev/null || echo "$vms_response"
    fi
else
    echo "❌ Failed to get VM list"
    echo "Response: $vms_response"
fi

echo ""
echo "4. Storage information..."
storage_response=$(curl -k -s -H "Authorization: $TOKEN" "$API_URL/nodes/$NODE/storage")
if echo "$storage_response" | grep -q "local-lvm"; then
    echo "✅ Storage 'local-lvm' is available"
else
    echo "❌ Storage 'local-lvm' not found"
    echo "Available storage:"
    echo "$storage_response" | jq -r '.data[].storage' 2>/dev/null || echo "$storage_response"
fi
