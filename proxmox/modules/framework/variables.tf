variable "proxmox" {
  description = "Proxmox configuration"
  type        = any
}

variable "platform" {
  description = "Platform variables"
  type        = any
}

variable "tags" {
  description = "Tags used for X-fields"
  type        = any
}

# Framework outputs for use by other modules
output "networking" {
  value = {
    bridge    = var.proxmox.bridge
    vlan_tag  = var.proxmox.vlan_tag
    node_name = var.proxmox.node_name
    storage   = var.proxmox.storage
  }
}
