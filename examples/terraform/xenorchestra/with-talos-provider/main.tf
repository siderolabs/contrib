
locals {
  size_1GB         = 1024 * 1024 * 1024
  cluster_endpoint = var.cluster_endpoint != null ? var.cluster_endpoint : "https://${var.cluster_vip}:6443"
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

data "xenorchestra_vdi" "iso" {
  count      = var.iso_name != null ? 1 : 0
  name_label = var.iso_name
  pool_id    = data.xenorchestra_pool.pool.id
}

resource "xenorchestra_vm" "cp" {
  memory_max       = var.cp_memory_gb * local.size_1GB
  cpus             = var.cp_cpus
  name_label       = "${var.cluster_name}-cp-${count.index}"
  name_description = "Talos CP created with Terraform"
  template         = var.tpl_talos_id

  hvm_boot_firmware = "uefi"
  secure_boot       = false

  dynamic "cdrom" {
    for_each = var.iso_name != null ? [1] : []
    content {
      id = data.xenorchestra_vdi.iso[0].id
    }
  }

  network {
    network_id       = data.xenorchestra_network.net.id
    expected_ip_cidr = var.expected_ip_cidr
  }

  disk {
    sr_id      = data.xenorchestra_sr.shared_storage.id
    name_label = "Talos OS disk"
    size       = var.cp_disk_size_gb * local.size_1GB
  }

  count = var.num_control_plane
}

resource "xenorchestra_vm" "worker" {
  memory_max       = var.worker_memory_gb * local.size_1GB
  cpus             = var.worker_cpus
  name_label       = "${var.cluster_name}-worker-${count.index}"
  name_description = "Talos Worker created with Terraform"
  template         = var.tpl_talos_id

  hvm_boot_firmware = "uefi"
  secure_boot       = false

  dynamic "cdrom" {
    for_each = var.iso_name != null ? [1] : []
    content {
      id = data.xenorchestra_vdi.iso[0].id
    }
  }

  network {
    network_id       = data.xenorchestra_network.net.id
    expected_ip_cidr = var.expected_ip_cidr
  }

  disk {
    sr_id      = data.xenorchestra_sr.shared_storage.id
    name_label = "Talos OS disk"
    size       = var.worker_disk_size_gb * local.size_1GB
  }

  count = var.num_workers
}

# Talos cluster configuration
resource "talos_machine_secrets" "this" {}

# Generate machine configurations in order to get the cloud-init userdata
data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = concat(
    var.iso_name != null ? [<<EOF
- op: add
  path: /machine/install
  value:
    disk: /dev/xvda
    image: factory.talos.dev/nocloud-installer/53b20d86399013eadfd44ee49804c1fef069bfdee3b43f3f3f5a2f57c03338ac:${var.talos_version}
EOF
    ] : [],
    [<<EOF
- op: add
  path: /machine/network
  value:
    interfaces:
      - interface: enX0
        dhcp: true
        vip:
          ip: "${var.cluster_vip}"
EOF
    ]
  )
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = local.cluster_endpoint
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  config_patches = var.iso_name != null ? [<<EOF
- op: add
  path: /machine/install
  value:
    disk: /dev/xvda
    image: factory.talos.dev/nocloud-installer/53b20d86399013eadfd44ee49804c1fef069bfdee3b43f3f3f5a2f57c03338ac:${var.talos_version}
EOF
  ] : []
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for vm in xenorchestra_vm.cp : vm.network[0].ipv4_addresses[0]]

  depends_on = [xenorchestra_vm.cp]
}

resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  count                       = length(xenorchestra_vm.cp)
  node                        = xenorchestra_vm.cp[count.index].network[0].ipv4_addresses[0]

  depends_on = [xenorchestra_vm.cp]
}

resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  count                       = length(xenorchestra_vm.worker)
  node                        = xenorchestra_vm.worker[count.index].network[0].ipv4_addresses[0]

  depends_on = [xenorchestra_vm.worker]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = xenorchestra_vm.cp[0].network[0].ipv4_addresses[0]

  depends_on = [talos_machine_configuration_apply.controlplane]
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = xenorchestra_vm.cp[0].network[0].ipv4_addresses[0]

  depends_on = [talos_machine_bootstrap.this]
}
