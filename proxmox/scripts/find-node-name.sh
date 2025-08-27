#!/bin/bash

# Script to find your Proxmox node name
# Run this script on your Proxmox host or from a machine that can access Proxmox

echo "=== Proxmox Node Discovery ==="
echo ""

# Method 1: Direct API call
echo "1. Testing API connection to get node list..."
response=$(curl -k -s -H "Authorization: PVEAPIToken=terraform@pve!terraform=a1c550c3-c05d-4e2f-b59f-72df158f86bb" \
    "https://192.168.220.200:8006/api2/json/nodes" 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$response" ]; then
    echo "API Response:"
    echo "$response" | jq -r '.data[].node' 2>/dev/null || echo "$response"
else
    echo "API call failed or no response"
fi

echo ""
echo "2. If you have SSH access to your Proxmox host, run these commands:"
echo ""
echo "   # Get hostname"
echo "   hostname"
echo ""
echo "   # Get cluster nodes"
echo "   pvecm nodes"
echo ""
echo "   # Get node status"
echo "   pvecm status"
echo ""
echo "3. Or check in the Proxmox web interface:"
echo "   - Login to https://192.168.220.200:8006"
echo "   - Look at the left sidebar under 'Datacenter'"
echo "   - The node name will be listed there"
echo ""
echo "4. Common node names are:"
echo "   - pve (default)"
echo "   - proxmox"
echo "   - Your server hostname"
echo ""
echo "Once you find the correct node name, update terraform.tfvars:"
echo "   node_name = \"your-actual-node-name\""
