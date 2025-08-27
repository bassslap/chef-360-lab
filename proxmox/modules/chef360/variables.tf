variable "admin_ip_address" {
  description = "Local public internet IP for use in security rules"
  type        = string
}

variable "networking" {
  description = "Network related variables"
  type        = any
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

variable "chef360" {
  description = "Chef 360 Platform Specific variables"
  type        = any
  
  validation {
    condition     = can(regex("^[0-9]+$", tostring(var.chef360.disk_size_gb)))
    error_message = "Disk size must be specified in GB as a number."
  }
}
