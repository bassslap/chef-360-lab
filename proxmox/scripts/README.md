# Proxmox Helper Scripts

This directory contains utility scripts for managing the Proxmox Chef 360 deployment.

## Template Management Scripts

- **`create-ubuntu-template.sh`** - Creates a new Ubuntu 22.04 cloud-init template for VM deployment
- **`create-template-api.sh`** - Alternative template creation script using Proxmox API
- **`setup-template.sh`** - Sets up and configures the VM template with required packages
- **`check-template.sh`** - Verifies that the VM template exists and is properly configured
- **`validate-template.sh`** - Validates template configuration and readiness for deployment
- **`fix-template-id.sh`** - Fixes template ID conflicts or issues
- **`quick-template-fix.sh`** - Quick fixes for common template problems

## VM Management Scripts

- **`cleanup-stale-vms.sh`** - Removes stale or orphaned VMs from Proxmox
- **`cleanup_stale_vms.sh`** - Alternative cleanup script (underscore version)
- **`remote-cleanup.sh`** - Performs remote cleanup operations on Proxmox host

## Utility Scripts

- **`find-node-name.sh`** - Discovers and displays Proxmox node names

## Usage

All scripts should be run from the proxmox directory root:

```bash
# Example: Create a template
./scripts/create-ubuntu-template.sh

# Example: Validate template
./scripts/validate-template.sh

# Example: Clean up stale VMs
./scripts/cleanup-stale-vms.sh
```

## Prerequisites

- SSH access to Proxmox host configured
- Proxmox API credentials set up
- Required environment variables or configuration files in place

## Notes

- Always review scripts before execution in production environments
- Some scripts may require root privileges on the Proxmox host
- Backup important data before running cleanup scripts
