#!/bin/bash

echo "=== Quick Ubuntu Template Setup ==="
echo ""
echo "Since VM 9000 seems to exist but may not be accessible, let's try a different approach."
echo ""
echo "Option 1: Use a different template ID"
echo "If you want to use an existing template with a different ID, update terraform.tfvars:"
echo ""
echo "# Find existing templates on your Proxmox host:"
echo "ssh root@192.168.220.200 'qm list | grep template'"
echo ""
echo "# Or list all VMs:"
echo "ssh root@192.168.220.200 'qm list'"
echo ""

echo "Option 2: Create template 9000 on Proxmox host"
echo "SSH to your Proxmox host and run these commands:"
echo ""

cat << 'EOF'
# Check if VM 9000 exists and remove it
if qm status 9000 >/dev/null 2>&1; then
    echo "VM 9000 exists, removing it..."
    qm stop 9000 || true
    qm destroy 9000 --purge || true
fi

# Download Ubuntu cloud image
cd /var/lib/vz/template/iso
if [ ! -f ubuntu-22.04-server-cloudimg-amd64.img ]; then
    wget -O ubuntu-22.04-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img
fi

# Create template
qm create 9000 --name ubuntu-22.04-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm disk import 9000 ubuntu-22.04-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --scsihw virtio-scsi-pci --boot order=scsi0
qm set 9000 --agent enabled=1
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm template 9000

echo "Template 9000 created successfully!"
EOF

echo ""
echo "Option 3: Use different template ID temporarily"
echo "Update terraform.tfvars to use template ID 999 instead:"

# Create a quick fix script
cat > fix-template-id.sh << 'SCRIPT'
#!/bin/bash
echo "Temporarily changing template_id from 9000 to 999..."
sed -i.bak 's/template_id.*=.*9000/template_id         = 999/' terraform.tfvars
echo "Updated terraform.tfvars - you can change it back after creating template 9000"
SCRIPT

chmod +x fix-template-id.sh

echo ""
echo "Created fix-template-id.sh - run it to temporarily use template 999"
echo ""
echo "To fix the immediate issue:"
echo "1. SSH to Proxmox and run the commands above to create template 9000"
echo "2. Or run ./fix-template-id.sh and create template 999 instead"
echo "3. Then run: tofu apply"
