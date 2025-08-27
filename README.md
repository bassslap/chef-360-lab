# chef-360-core

## Terraform Plan for the Chef 360 Platform Provisioning

This is a start from scratch Terraform plan to install the base platform for Chef 360 Installation.

This is based on the https://github.com/chef-cft/sa-demo-core/ provisioning plan that installs Chef Automate with Infra, a workstation and however many nodes are needed.

## Supported Platforms

### Azure Cloud
- **[Azure README](./azure/README.md)** - Complete Azure deployment guide
- **[Azure Post-Provision Guide](./azure/chef360.md)** - Setup steps after infrastructure deployment
- **Features**: Managed networking, Let's Encrypt SSL, Azure DNS integration

### Proxmox VE
- **[Proxmox README](./proxmox/README.md)** - Complete Proxmox deployment guide  
- **[Proxmox Post-Provision Guide](./proxmox/chef360.md)** - Setup steps after infrastructure deployment
- **Features**: Self-hosted virtualization, complete infrastructure control, cost-effective

## Platform Comparison

| Feature | Azure | Proxmox |
|---------|-------|---------|
| **Cost** | Pay-per-use cloud pricing | One-time hardware investment |
| **Management** | Fully managed services | Self-managed infrastructure |
| **Networking** | Managed DNS, Load Balancers | Full network control |
| **SSL Certificates** | Let's Encrypt integration | Self-signed (customizable) |
| **Scalability** | Auto-scaling capabilities | Manual scaling |
| **Best For** | Cloud-first, managed ops | On-premises, cost control |

Thanks!
Mike Butler
