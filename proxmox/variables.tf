/*************************************
      Chef 360 Core - Proxmox Terraform Plan
          version: 0.3.0
**************************************/

/*************************************
  Global TF Vars           
**************************************/
variable "tags" {
  description = "Tags to apply to all resources"
  type        = list(string)
  default     = ["chef360", "lab"]
}

/**************************************
  Universal Platform Vars
  Description:  Platform variables that are independant of which cloud platform is selected
***************************************/
variable "platform" {
  description = "Platform variables that are independant of which cloud platform is selected"
  type = object({
    dns_shortname      = string
    dns_zone           = string
    os_name            = string
    os_version         = string
    linux_node_count   = number
    windows_node_count = number
  })
}

/**************************************
  Proxmox TF Vars                
  Description:  Proxmox specific variables required for deployment
***************************************/

# Individual variables for BPG provider
variable "proxmox_host" {
  description = "Proxmox server hostname or IP address"
  type        = string
}

variable "api_user" {
  description = "Proxmox API user (format: user@realm)"
  type        = string
}

variable "api_token_name" {
  description = "Proxmox API token name"
  type        = string
}

variable "api_token_value" {
  description = "Proxmox API token value"
  type        = string
  sensitive   = true
}

# Main proxmox configuration - UPDATED to match your tfvars
variable "proxmox" {
  description = "Proxmox specific variables required for deployment"
  type = object({
    endpoint         = string
    api_token_id     = string
    api_token_secret = string
    node_name        = string
    public_key_file  = string
    template_id      = number
  })
}

# Networking configuration - ADDED to match your tfvars
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

/***************************************
  Proxmox OS Variables
  Description: Variables not typically changed by user
****************************************/
variable "proxmox_credentials" {
  description = "Proxmox VM credentials"
  type = object({
    vm_user     = string
    vm_password = string
  })
  default = {
    vm_user     = "ubuntu"
    vm_password = "ubuntu123!"  # Updated password
  }
}

/***************************************
  Chef-360 Specific Variables
  Description: Chef 360 required variables
****************************************/
variable "chef360" {
  description = "Chef 360 specific variables required for deployment"
  type = object({
    cores           = number
    memory          = number
    disk_size_gb    = number
    ip_address      = string
    replicated_key  = string
    chef360_channel = string
    local_fqdn      = string
  })
}

# Workstation configuration
variable "workstation" {
  description = "Workstation VM configuration"
  type = object({
    cores        = number
    memory       = number
    disk_size_gb = number
    ip_address   = string
    ssl_private_key = string
    ssl_public_key  = string

  })
}

# Linux nodes configuration
variable "linux_nodes" {
  description = "Linux nodes configuration"
  type = object({
    count        = number
    ip_start     = string
    cores        = number
    memory       = number
    disk_size_gb = number
    name_prefix  = string
  })
}