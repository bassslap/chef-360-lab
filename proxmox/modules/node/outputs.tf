output "linux_hosts" {
  value = proxmox_virtual_environment_vm.linux_nodes[*]
}

output "hosts" {
  value = concat(proxmox_virtual_environment_vm.linux_nodes[*])
}

output "node_ips" {
  description = "IP addresses of created nodes"
  value       = local.node_ips
}

output "node_names" {
  description = "Names of created nodes"
  value       = [for i in range(var.linux_nodes.count) : 
                 "${var.linux_nodes.name_prefix}-${format("%02d", i + 1)}"]
}