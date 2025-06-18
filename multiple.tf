terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.78.1"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://192.168.0.253:8006/api2/json"
  username  = "root@pam"
  password  = "RabbiT!2025"
  insecure  = true
}

locals {
  vms = {
    "vm-1" = {
      vm_id      = 200
      name       = "test1"
      iso        = "local:iso/Win11_24H2_German_x64.iso"
      cpu_cores  = 2
      memory     = 4096     
      disk_size  = 100      
    }
    "vm-2" = {
      vm_id      = 201
      name       = "test2"
      iso        = "local:iso/Win11_24H2_German_x64.iso"
      cpu_cores  = 2
      memory     = 4096
      disk_size  = 200
    }
    "vm-3" = {
      vm_id      = 202
      name       = "test3"
      iso        = "local:iso/Win11_24H2_German_x64.iso"
      cpu_cores  = 2
      memory     = 4096
      disk_size  = 50
    } 
  }
}

resource "proxmox_virtual_environment_vm" "multi_vm" {
  for_each   = local.vms

  vm_id      = each.value.vm_id
  name       = each.value.name
  node_name  = "taxi"

  machine = "pc-q35-9.2+pve1"

  bios            = "ovmf"
  scsi_hardware   = "virtio-scsi-single"
  started         = true

  agent {
    enabled = true
  }

  cpu {
    cores   = each.value.cpu_cores
    sockets = 1
    type    = "host"
    units = 1024
  }

  memory {
    dedicated = each.value.memory
    floating = each.value.memory
  }

  cdrom {
    interface = "ide0"
    file_id   = each.value.iso
  }

  network_device {
    bridge   = "vmbr0"
    model    = "virtio"
    firewall = true
  }

  disk {
    interface     = "sata0"
    datastore_id  = "local-zfs"
    backup        = true
    size          = each.value.disk_size
    ssd           = true
    cache         = "none"
  }

  efi_disk {
    datastore_id = "local-zfs"
    type = "4m"
    pre_enrolled_keys = true
  }
  tpm_state {
    version = "v2.0"
    datastore_id = "local-zfs"
  }
}


locals {
  cdrom_commands = [
    for vm in local.vms : "qm set ${vm.vm_id} --ide2 local:iso/virtio-win-0.1.271.iso,media=cdrom"
  ]
  stop_commands = [
    for vm in local.vms : "qm stop ${vm.vm_id} --overrule"
  ]
  startup_commands = [
    for vm in local.vms : "qm start ${vm.vm_id}"
  ]
}

resource "null_resource" "add_cdrom" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "remote-exec" {
    inline = concat(
      ["sleep 30"],
      local.cdrom_commands,
      ["sleep 30"],
      local.stop_commands,
      ["sleep 30"],
      local.startup_commands
    )

    connection {
      type     = "ssh"
      host     = "192.168.0.253"
      user     = "root"
      password = "RabbiT!2025"
      port     = 22
    }
  }
}
