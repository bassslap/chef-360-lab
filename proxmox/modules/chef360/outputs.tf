output "private_ip_address" {
  value = length(proxmox_virtual_environment_vm.chef360[0].ipv4_addresses) > 0 ? (
    length(proxmox_virtual_environment_vm.chef360[0].ipv4_addresses) > 1 ? 
      proxmox_virtual_environment_vm.chef360[0].ipv4_addresses[1][0] : 
      proxmox_virtual_environment_vm.chef360[0].ipv4_addresses[0][0]
  ) : null
}

output "public_ip_address" {
  value = length(proxmox_virtual_environment_vm.chef360[0].ipv4_addresses) > 0 ? (
    length(proxmox_virtual_environment_vm.chef360[0].ipv4_addresses) > 1 ? 
      proxmox_virtual_environment_vm.chef360[0].ipv4_addresses[1][0] : 
      proxmox_virtual_environment_vm.chef360[0].ipv4_addresses[0][0]
  ) : null
}

output "vm_name" {
  value = proxmox_virtual_environment_vm.chef360[0].name
}
