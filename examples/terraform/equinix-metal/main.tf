# Create EM resources
resource "equinix_metal_reserved_ip_block" "talos_control_plane_vip" {
  project_id  = var.em_project_id
  type        = "public_ipv4"
  metro       = var.em_region
  tags        = var.extra_tags
  quantity    = 1
  description = "${var.cluster_name} Control Plane VIP"
}

resource "equinix_metal_device" "talos_control_plane_nodes" {
  count = var.control_plane.num_instances

  project_id       = var.em_project_id
  plan             = var.control_plane.plan
  metro            = var.em_region
  tags             = concat(var.extra_tags, var.control_plane.tags)
  operating_system = "custom_ipxe"
  ipxe_script_url  = var.control_plane.ipxe_script_url
  billing_cycle    = "hourly"
  hostname         = "${var.cluster_name}-control-plane-${count.index}"
}

resource "equinix_metal_device" "talos_worker_group" {
  for_each = merge([
    for info in var.worker_groups : {
      for index in range(0, info.num_instances) : "${info.name}.${index}" => info
    }
  ]...)

  project_id       = var.em_project_id
  plan             = each.value.plan
  metro            = var.em_region
  tags             = concat(var.extra_tags, each.value.tags)
  operating_system = "custom_ipxe"
  ipxe_script_url  = each.value.ipxe_script_url
  billing_cycle    = "hourly"
  hostname         = "${var.cluster_name}-worker-group-${each.value.name}-${trimprefix(each.key, "${each.value.name}.")}"
}

# Configure and bootstrap Talos

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${equinix_metal_reserved_ip_block.talos_control_plane_vip.network}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches = concat(
    [templatefile("${path.module}/templates/vip.yaml.tmpl", {
      em_vip_ip    = equinix_metal_reserved_ip_block.talos_control_plane_vip.network
      em_api_token = var.em_api_token
    })],
    [templatefile("${path.module}/templates/installer.yaml.tmpl", {
      install_image = var.control_plane.install_image
    })],
    [for path in var.control_plane.config_patch_files : file(path)]
  )
}

data "talos_machine_configuration" "worker_group" {
  for_each = merge([for info in var.worker_groups : { "${info.name}" = info }]...)

  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${equinix_metal_reserved_ip_block.talos_control_plane_vip.network}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches = concat(
    [templatefile("${path.module}/templates/installer.yaml.tmpl", {
      install_image = each.value.install_image
    })],
    [for path in each.value.config_patch_files : file(path)]
  )
}

resource "talos_machine_configuration_apply" "controlplane" {
  count = var.control_plane.num_instances

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  endpoint                    = equinix_metal_device.talos_control_plane_nodes[count.index].access_public_ipv4
  node                        = equinix_metal_device.talos_control_plane_nodes[count.index].access_private_ipv4
}

resource "talos_machine_configuration_apply" "worker_group" {
  for_each = merge([
    for info in var.worker_groups : {
      for index in range(0, info.num_instances) :
      "${info.name}.${index}" => {
        name       = info.name,
        public_ip  = equinix_metal_device.talos_worker_group["${info.name}.${index}"].access_public_ipv4,
        private_ip = equinix_metal_device.talos_worker_group["${info.name}.${index}"].access_private_ipv4
      }
    }
  ]...)

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker_group[each.value.name].machine_configuration
  endpoint                    = each.value.public_ip
  node                        = each.value.private_ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = equinix_metal_device.talos_control_plane_nodes[0].access_public_ipv4
  node                 = equinix_metal_device.talos_control_plane_nodes[0].access_public_ipv4
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = equinix_metal_device.talos_control_plane_nodes.*.access_public_ipv4
  nodes                = flatten([equinix_metal_device.talos_control_plane_nodes.*.access_public_ipv4, flatten([for node in equinix_metal_device.talos_worker_group : node.access_public_ipv4])])
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = equinix_metal_device.talos_control_plane_nodes.0.access_public_ipv4
  node                 = equinix_metal_device.talos_control_plane_nodes.0.access_public_ipv4
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker_group,
    talos_cluster_kubeconfig.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = equinix_metal_device.talos_control_plane_nodes.*.access_public_ipv4
  control_plane_nodes  = equinix_metal_device.talos_control_plane_nodes.*.access_private_ipv4
  worker_nodes         = [for node in equinix_metal_device.talos_worker_group : node.access_private_ipv4]
}
