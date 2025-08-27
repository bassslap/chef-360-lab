#!/bin/bash
# Chef 360 VM Cleanup Script
# Combines Proxmox VM cleanup and Terraform destroy

set -e

echo "=== Chef 360 Proxmox VM LAB Cleanup ==="
echo ""

# Check for cleanup mode argument
CLEANUP_MODE=${1:-"full"}

case $CLEANUP_MODE in
    "full")
        echo "Mode: Full cleanup (Proxmox VMs + Terraform)"
        DO_TERRAFORM=true
        DO_PROXMOX=true
        ;;
    "terraform")
        echo "Mode: Terraform state cleanup only"
        DO_TERRAFORM=true
        DO_PROXMOX=false
        ;;
    "proxmox")
        echo "Mode: Proxmox VM cleanup only"
        DO_TERRAFORM=false
        DO_PROXMOX=true
        ;;
    *)
        echo "Usage: $0 [full|terraform|proxmox]"
        echo "  full      - Clean up both Proxmox VMs and Terraform state (default)"
        echo "  terraform - Clean up Terraform state only"
        echo "  proxmox   - Clean up Proxmox VMs only"
        exit 1
        ;;
esac

# Step 1: Proxmox VM Cleanup
if [ "$DO_PROXMOX" = true ]; then
    echo "Step 1: Proxmox VM cleanup..."
    
    # Extract Proxmox IP dynamically from terraform.tfvars
    echo "Extracting Proxmox IP from terraform.tfvars..."

    # Better extraction that ignores comments
    PROXMOX_IP=$(grep "endpoint.*https" terraform.tfvars | sed 's/.*https:\/\/\([0-9.]*\):.*/\1/' | head -1)

    # Alternative method if first fails
    if [ -z "$PROXMOX_IP" ]; then
        PROXMOX_IP=$(grep -o '192\.168\.220\.200' terraform.tfvars | head -1)
    fi

    # Clean up any whitespace or extra characters
    PROXMOX_IP=$(echo "$PROXMOX_IP" | tr -d ' ' | grep -o '[0-9.]*')

    if [ -z "$PROXMOX_IP" ]; then
        echo "Error: Could not extract Proxmox IP from terraform.tfvars"
        echo "Falling back to hardcoded IP: 192.168.220.200"
        PROXMOX_IP="192.168.220.200"
    fi

    echo "Using Proxmox IP: $PROXMOX_IP"

    # Validate IP format
    if [[ ! $PROXMOX_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Warning: IP format looks invalid: '$PROXMOX_IP'"
        echo "Using fallback IP: 192.168.220.200"
        PROXMOX_IP="192.168.220.200"
    fi

    # Check if cleanup script exists
    CLEANUP_SCRIPT="cleanup_stale_vms.sh"
    if [ ! -f "$CLEANUP_SCRIPT" ]; then
        echo "Warning: $CLEANUP_SCRIPT not found in current directory"
        echo "Skipping Proxmox VM cleanup"
    else
        echo ""
        echo "Uploading cleanup script to Proxmox..."
        scp $CLEANUP_SCRIPT root@$PROXMOX_IP:/tmp/

        echo ""
        echo "Executing cleanup script on Proxmox..."
        ssh root@$PROXMOX_IP "chmod +x /tmp/$CLEANUP_SCRIPT && /tmp/$CLEANUP_SCRIPT --yes"

        # Optional: Clean up the uploaded script
        read -p "Remove cleanup script from Proxmox? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh root@$PROXMOX_IP "rm -f /tmp/$CLEANUP_SCRIPT"
            echo "✓ Cleanup script removed from Proxmox"
        fi
    fi
    echo ""
fi

# Step 2: Terraform Cleanup
if [ "$DO_TERRAFORM" = true ]; then
    echo "Step 2: Terraform cleanup..."
    echo ""
    
    # Check if we're in a Terraform directory
    if [ ! -f "main.tf" ] && [ ! -f "terraform.tfvars" ]; then
        echo "Warning: No Terraform files found. Are you in the right directory?"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo "Running Terraform destroy..."
    if tofu destroy -auto-approve; then
        echo "✓ Terraform destroy completed successfully"
    else
        echo "⚠ Terraform destroy failed or was cancelled"
        echo "Manual cleanup may be required"
    fi
    echo ""
fi

echo ""
echo "✓ Chef360 VM LAB cleanup completed successfully!"

# Optional: Clean up local Terraform files
if [ "$DO_TERRAFORM" = true ]; then
    echo ""
    read -p "Also clean up local Terraform_OpenTofu state files? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f terraform.tfstate*
        rm -rf .terraform/
        rm -f .terraform.lock.hcl
        echo "✓ Local Terraform files cleaned up"
    fi
fi

echo "Done!"