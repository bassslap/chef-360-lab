locals {
  basename = "chef360"
  
  # Template file with variables
  user_data_script = templatefile("${path.module}/templates/chef360.tpl", {
    replicated_key  = var.chef360.replicated_key
    chef360_channel = var.chef360.chef360_channel
  })
}

resource "local_file" "chef360_userdata" {
  count = 1
  content = templatefile("${path.module}/templates/chef360-cloud-init.yml", {
    hostname         = format("%s-linux-%02g", local.basename, "1")
    ip_address       = var.chef360.ip_address     # Now uses tfvars value!
    gateway          = var.networking.gateway     # Now uses tfvars value!
    ssh_public_key   = trimspace(file(var.proxmox.public_key_file))
    user_data_script = base64encode(local.user_data_script)
  })
  filename = "${path.root}/tmp/chef360-userdata-1.yml"
}

resource "null_resource" "copy_snippet_to_proxmox" {
  depends_on = [local_file.chef360_userdata]
  triggers = {
    src_hash = sha256(local_file.chef360_userdata[0].content)
  }

  provisioner "local-exec" {
    command = "scp ${local_file.chef360_userdata[0].filename} root@192.168.220.200:/var/lib/vz/snippets/"
  }
}

# Create Chef 360 VM
resource "proxmox_virtual_environment_vm" "chef360" {
  count     = 1
  name      = local.basename
  node_name = var.networking.node_name
  tags      = var.tags
  
  # VM Configuration
  cpu {
    cores = var.chef360.cores
    type  = "x86-64-v2-AES"
  }
  
  memory {
    dedicated = var.chef360.memory
  }
  
  # Network Device
  network_device {
    bridge = var.networking.bridge
    model  = "virtio"
    vlan_id = var.networking.vlan_tag != 0 ? var.networking.vlan_tag : null
  }
  
  # Disk
  disk {
    datastore_id = var.networking.storage
    interface    = "scsi0"
    iothread     = true
    size         = var.chef360.disk_size_gb
    file_format  = "raw"
  }
  
  # Clone from template
  clone {
    vm_id = var.proxmox.template_id
    full  = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.chef360.ip_address}/23"
        gateway = var.networking.gateway
      }
    }
    dns {
      domain  = "lab.local"
      servers = ["8.8.8.8", "1.1.1.1"]
    }
    user_data_file_id = "local:snippets/chef360-userdata-1.yml"
  }

  depends_on = [null_resource.copy_snippet_to_proxmox]

  agent {
    enabled = true
    timeout = "15m"
  }
  
  # Operating system type
  operating_system {
    type = "l26"
  }
  
  # Lifecycle rules
  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
      vga,
      tags
    ]
    create_before_destroy = false
  }
  
  stop_on_destroy = true
  on_boot = true

}



