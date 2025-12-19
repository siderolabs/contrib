
locals {
  size_1GB = 1024 * 1024 * 1024
}

data "xenorchestra_pool" "pool" {
  name_label = var.pool_name
}

data "xenorchestra_sr" "shared_storage" {
  name_label = var.sr_name
}

data "xenorchestra_network" "net" {
  name_label = var.network_name
  pool_id    = data.xenorchestra_pool.pool.id
}

resource "xenorchestra_vm" "cp" {
  memory_max   = var.cp_memory_gb * local.size_1GB
  cpus         = var.cp_cpus
  cloud_config = file("${path.module}/controlplane.yaml")

  name_label       = "${var.cluster_name}-cp"
  name_description = "Talos CP created with Terraform"
  template         = var.tpl_talos_id

  hvm_boot_firmware = "uefi"
  secure_boot       = false

  network {
    network_id = data.xenorchestra_network.net.id
  }

  disk {
    sr_id      = data.xenorchestra_sr.shared_storage.id
    name_label = "Talos OS disk"
    size       = var.cp_disk_size_gb * local.size_1GB
  }
}

resource "xenorchestra_vm" "worker" {
  memory_max   = var.worker_memory_gb * local.size_1GB
  cpus         = var.worker_cpus
  cloud_config = file("${path.module}/worker.yaml")

  name_label       = "${var.cluster_name}-worker"
  name_description = "Talos Worker created with Terraform"
  template         = var.tpl_talos_id

  hvm_boot_firmware = "uefi"
  secure_boot       = false

  network {
    network_id = data.xenorchestra_network.net.id
  }

  disk {
    sr_id      = data.xenorchestra_sr.shared_storage.id
    name_label = "Talos OS disk"
    size       = var.worker_disk_size_gb * local.size_1GB
  }
}