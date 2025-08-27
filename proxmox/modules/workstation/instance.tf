locals {
  // Base name used for resources
  basename = "workstation"

  # Template file with variables
  user_data_script = templatefile("${path.module}/templates/workstation.tpl", {
    ssl_private_key = file("~/.ssh/id_rsa")                           # SSH private key
    ssl_public_key  = trimspace(file(var.proxmox.public_key_file))    # SSH public key from config
    local_fqdn      = var.chef360.local_fqdn
    ip_address      = var.chef360.ip_address
  })
}

resource "local_file" "workstation_userdata" {
  count = 1
  content = templatefile("${path.module}/templates/workstation-cloud-init.yml", {
    hostname         = format("%s-%02g", local.basename, "1")
    ip_address       = var.workstation.ip_address
    gateway          = var.networking.gateway
    ssh_public_key   = trimspace(file(var.proxmox.public_key_file))
    user_data_script = base64encode(local.user_data_script)
  })
  filename = "${path.root}/tmp/workstation-userdata-1.yml"
}

resource "null_resource" "copy_snippet_to_proxmox" {
  depends_on = [local_file.workstation_userdata]
  triggers = {
    src_hash = sha256(local_file.workstation_userdata[0].content)
  }

  provisioner "local-exec" {
    command = "scp ${local_file.workstation_userdata[0].filename} root@192.168.220.200:/var/lib/vz/snippets/"
  }
}
resource "proxmox_virtual_environment_vm" "workstation" {
  count       = 1
  vm_id       = 101
  node_name   = var.networking.node_name
  name        = format("%s-%02g", local.basename, "1")
  description = "Chef Workstation"
  tags        = var.tags

  agent {
    enabled = true
    trim    = true
  }

  #bios = "ovmf"

  cpu {
    cores = var.workstation.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.workstation.memory
  }

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
    size         = var.workstation.disk_size_gb
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
        address = "${var.workstation.ip_address}/23"
        gateway = var.networking.gateway
      }
    }
    
    user_account {
      keys     = [trimspace(file(var.proxmox.public_key_file))]
      username = var.proxmox_credentials.vm_user
      password = var.proxmox_credentials.vm_password
    }
    dns {
      domain  = "lab.local"
      servers = ["8.8.8.8", "1.1.1.1"]
    }
    user_data_file_id = "local:snippets/workstation-userdata-1.yml"
  }

  depends_on = [null_resource.copy_snippet_to_proxmox]

  operating_system {
    type = "l26"
  }

  #serial_device {}

  vga {
    type = "serial0"
  }

  started        = true
  template       = false
  stop_on_destroy = true
  on_boot        = true
}