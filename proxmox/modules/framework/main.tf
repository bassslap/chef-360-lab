# Framework module for Proxmox
# This module handles basic networking setup

locals {
  basename = format("%s-%s", var.platform.dns_shortname, var.tags.X-Project)
}
