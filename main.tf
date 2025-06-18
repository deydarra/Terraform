terraform {
  required_providers {
    proxmox = {
        source = "bpg/proxmox"
        version = ">=0.44.0"
    }
  }
}

provider "proxmox" {
    endpoint = "https://192.168.0.253:8006/api2/json"
    username = "root@pam"
    password = "RabbiT!2025"
    insecure = true
}

# -------------------------------------------------------------
#   First VM Win11
# -------------------------------------------------------------
resource "proxmox_virtual_environment_vm" "test" {
    vm_id = 200
    name = "test"
    description = "Test-Win11"
    node_name = "taxi" 
    
    bios = "ovmf"
    scsi_hardware = "virtio-scsi-pci"

    agent{
        enabled = true
    }


    cpu{
        cores = 4
        sockets = 1
        type = "host"
    }
    
    memory{
        dedicated = 8192
    } 
    
    
    cdrom{
        interface = "ide0"
        file_id = "local:iso/Win11_24H2_German_x64.iso"
        #file_id = "local:iso/virtio-win-0.1.271.iso"
    }
       
    network_device {
        bridge = "vmbr0"
        model = "virtio"
        firewall = true
    }

    disk {
        interface = "sata0"
        datastore_id = "local-zfs"
        backup = true
        size = 100
        ssd = true
        cache = "none"
    }

    efi_disk {
        datastore_id = "local-zfs"
    }   

    started = true

}
# -------------------------------------------------------------
#   First VM Win11
# -------------------------------------------------------------

