output "Chef360_Private_IP_Address" {
  value = module.chef360.private_ip_address
}

output "Chef360_Public_IP_Address" {
  value = module.chef360.public_ip_address
}

output "VM_Username" {
  value = var.proxmox_credentials.vm_user
}

output "VM_Password" {
  value = var.proxmox_credentials.vm_password
}

output "Workstation_IP_Address" {
  value = module.workstation.public_ip_address != null ? module.workstation.public_ip_address : "Waiting for VM to get IP address..."
}

output "Chef_Linux_Nodes" {
  sensitive = false
  value     = zipmap(module.node.linux_hosts[*].name, [for vm in module.node.linux_hosts : length(vm.ipv4_addresses) > 1 ? vm.ipv4_addresses[1][0] : (length(vm.ipv4_addresses) > 0 ? vm.ipv4_addresses[0][0] : "")])
}

output "SSL_Certificate_Files" {
  value = {
    private_key  = "./tmp/${local.chef_platform_fqdn}.key.pem"
    certificate  = "./tmp/${local.chef_platform_fqdn}.chain.pem"
    common_name  = local.chef_platform_fqdn
  }
  description = "SSL certificate files for Chef 360 configuration"
}
