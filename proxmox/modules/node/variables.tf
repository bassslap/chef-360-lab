variable "admin_ip_address" {
  description = "Local public internet IP for use in security rules"
  type        = string
}

variable "tags" {
  description = "Tags used for X-fields"
  type        = any
}

variable "platform" {
  description = "Platform variables"
  type        = any
}

variable "proxmox" {
  description = "General Proxmox related variables"
  type        = any
}

variable "proxmox_credentials" {
  description = "Proxmox credentials related variables"
  type        = any
}
# Add this to modules/node/variables.tf

variable "linux_nodes" {
  description = "Linux nodes configuration"
  type        = any
  
  validation {
    condition     = can(regex("^[0-9]+$", tostring(var.linux_nodes.disk_size_gb)))
    error_message = "Disk size must be specified in GB as a number."
  }
}

# Keep your existing variables too:
variable "networking" {
  description = "Networking configuration"
  type = object({
    bridge      = string
    storage     = string
    node_name   = string
    vlan_tag    = number
    gateway     = string
    dns_servers = list(string)
  })
}
