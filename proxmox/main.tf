terraform {
  required_version = ">= 1.3"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.66.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

locals {
  #my_ip = chomp(data.http.myip.response_body)
  # Use admin IP from chef360 IP address
  admin_ip = var.chef360.ip_address
  # Create a simple local FQDN for SSL certificates
  chef_platform_fqdn = "chef360.lab.local"
}

# Configure the Proxmox provider
provider "proxmox" {
  endpoint  = var.proxmox.endpoint
  api_token = "${var.proxmox.api_token_id}=${var.proxmox.api_token_secret}"
  insecure  = true

  ssh {
    agent    = true
    username = "root"
    private_key = file("~/.ssh/id_rsa")  # Add your private key
  }
}

# Get the local public IP address running the terraform plan
# data "http" "myip" {
#   url = "http://ipv4.icanhazip.com"
# }

# Deploy Chef 360 VM
module "chef360" {
  source = "./modules/chef360"

  chef360             = var.chef360
  networking          = var.networking
  proxmox             = var.proxmox
  tags                = var.tags
  platform            = var.platform
  proxmox_credentials = var.proxmox_credentials
  admin_ip_address    = local.admin_ip
}

# Deploy Workstation VM
module "workstation" {
  source = "./modules/workstation"
  
  workstation         = var.workstation
  networking          = var.networking
  proxmox             = var.proxmox
  tags                = var.tags
  platform            = var.platform
  proxmox_credentials = var.proxmox_credentials
  admin_ip_address    = local.admin_ip
  chef360             = var.chef360
}

# Deploy Linux Nodes
module "node" {
  source = "./modules/node"
  linux_nodes          = var.linux_nodes
  networking           = var.networking
  proxmox              = var.proxmox
  tags                 = var.tags
  platform             = var.platform
  proxmox_credentials  = var.proxmox_credentials
  admin_ip_address     = local.admin_ip
}

# Generate SSL certificates for Chef 360
resource "tls_private_key" "chef360_ssl" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "chef360_ssl" {
  private_key_pem = tls_private_key.chef360_ssl.private_key_pem

  subject {
    common_name  = local.chef_platform_fqdn
    organization = "Chef 360 Lab"
  }

  validity_period_hours = 8760  # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = [
    local.chef_platform_fqdn,
    var.chef360.ip_address,
    "localhost"
  ]

  ip_addresses = [
    var.chef360.ip_address,
    "127.0.0.1"
  ]
}

# Create proxmox/tmp directory
resource "local_file" "proxmox_tmp_directory" {
  content  = ""
  filename = "${path.module}/tmp/.keep"
}

# Write private key to proxmox/tmp
resource "local_file" "chef360_private_key" {
  content         = tls_private_key.chef360_ssl.private_key_pem
  filename        = "${path.module}/tmp/${local.chef_platform_fqdn}.key.pem"
  file_permission = "0600"
  
  depends_on = [local_file.proxmox_tmp_directory]
}

# Write certificate to proxmox/tmp
resource "local_file" "chef360_certificate" {
  content         = tls_self_signed_cert.chef360_ssl.cert_pem
  filename        = "${path.module}/tmp/${local.chef_platform_fqdn}.chain.pem"
  file_permission = "0644"
  
  depends_on = [local_file.proxmox_tmp_directory]
}
# Output VM information
output "chef360_ip" {
  description = "Chef 360 VM IP address"
  value       = var.chef360.ip_address
}

output "workstation_ip" {
  description = "Workstation VM IP address"  
  value       = var.workstation.ip_address
}

output "linux_nodes_info" {
  description = "Linux nodes information"
  value = {
    count    = var.linux_nodes.count
    ip_start = var.linux_nodes.ip_start
    ips      = [for i in range(var.linux_nodes.count) : 
                "${split(".", var.linux_nodes.ip_start)[0]}.${split(".", var.linux_nodes.ip_start)[1]}.${split(".", var.linux_nodes.ip_start)[2]}.${parseint(split(".", var.linux_nodes.ip_start)[3], 10) + i}"]
  }
}

output "access_info" {
  description = "Access information for all VMs"
  value = {
    chef360_dashboard     = "http://${var.chef360.ip_address}:30000"
    chef360_platform      = "http://${var.chef360.ip_address}:31000"
    chef360_fqdn_dashboard = "http://${local.chef_platform_fqdn}:30000"
    chef360_fqdn_platform  = "http://${local.chef_platform_fqdn}:31000"
    chef_platform_fqdn    = local.chef_platform_fqdn
    mailpit              = "http://${var.chef360.ip_address}:31101"
    ssh_password         = "ubuntu123!"
    ssl_certificates = {
      private_key  = "${path.module}/tmp/${local.chef_platform_fqdn}.key.pem"
      certificate  = "${path.module}/tmp/${local.chef_platform_fqdn}.chain.pem"
    }
  }
}