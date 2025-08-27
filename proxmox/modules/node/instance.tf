locals {
  # Calculate IP addresses for each node starting from ip_start
  base_ip_parts = split(".", var.linux_nodes.ip_start)
  base_ip_int = parseint(local.base_ip_parts[3], 10)
  node_ips = [for i in range(var.linux_nodes.count) : 
              "${local.base_ip_parts[0]}.${local.base_ip_parts[1]}.${local.base_ip_parts[2]}.${local.base_ip_int + i}"]

  basename = "linux-node"
  user_data_script = fileexists("${path.module}/templates/node-install.sh") ? file("${path.module}/templates/node-install.sh") : "#!/bin/bash\necho 'Node setup completed'"
}

resource "local_file" "linux_node_userdata" {
  count = var.linux_nodes.count
  content = templatefile("${path.module}/templates/node-linux-cloud-init.yml", {
    hostname       = format("%s-linux-%02g", local.basename, count.index + 1)
    ip_address     = local.node_ips[count.index]
    gateway        = var.networking.gateway
    ssh_public_key = trimspace(file(var.proxmox.public_key_file))
    user_data_script = base64encode(local.user_data_script)
  })
  #filename = "/tmp/node-linux-userdata-${count.index + 1}.yml"
  filename = "${path.root}/tmp/node-linux-userdata-${count.index + 1}.yml"
}

resource "null_resource" "copy_snippet_to_proxmox" {
  count = var.linux_nodes.count
  depends_on = [local_file.linux_node_userdata]
  triggers = {
    src_hash = sha256(local_file.linux_node_userdata[count.index].content)
  }

  provisioner "local-exec" {
    command = "scp ${local_file.linux_node_userdata[count.index].filename} root@192.168.220.200:/var/lib/vz/snippets/"
  }
}

resource "proxmox_virtual_environment_vm" "linux_nodes" {
  count     = var.linux_nodes.count
  vm_id     = 102 + count.index
  name      = "${var.linux_nodes.name_prefix}-${format("%02d", count.index + 1)}"
  node_name = var.networking.node_name
  description = "Chef Node ${count.index + 1}"
  tags      = var.tags

  agent {
    enabled = true
    timeout = "15m"
  }
  
  cpu {
    cores = var.linux_nodes.cores
    type  = "x86-64-v2-AES"
  }
  
  memory {
    dedicated = var.linux_nodes.memory
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
    size         = var.linux_nodes.disk_size_gb
    file_format  = "raw"
  }
  
  # Clone from template
  clone {
    vm_id = var.proxmox.template_id
    full  = true
  }

  # efi_disk {
  #   datastore_id = "proxmox_storage_1"  # Changed from local-lvm
  #   file_format  = "raw"
  #   type         = "4m"
  # }

  # tpm_state {
  #   datastore_id = "proxmox_storage_1"  # Changed from local-lvm
  # }
  
  initialization {
    ip_config {
      ipv4 {
        address = "${local.node_ips[count.index]}/23"
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
    user_data_file_id = "local:snippets/node-linux-userdata-${count.index + 1}.yml"
  }

  depends_on = [null_resource.copy_snippet_to_proxmox]
  
  operating_system {
    type = "l26"
  }

  serial_device {}

  vga {
    type = "serial0"
  }
  
  started         = true
  template        = false
  stop_on_destroy = true
  on_boot         = true
}

