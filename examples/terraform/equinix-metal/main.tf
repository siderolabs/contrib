# Create EM resources

resource "equinix_metal_reserved_ip_block" "talos_control_plane_vip" {
  project_id  = var.em_project_id
  type        = "public_ipv4"
  metro       = var.em_region
  quantity    = 1
  description = "${var.cluster_name} Control Plane VIP"
}

resource "equinix_metal_device" "talos_control_plane" {
  project_id       = var.em_project_id
  plan             = var.em_plan
  metro            = var.em_region
  operating_system = "talos_v1"
  billing_cycle    = "hourly"
  hostname         = "${var.cluster_name}-control-plane-${count.index}"
  count            = var.num_control_plane
}

resource "equinix_metal_device" "talos_worker" {
  project_id       = var.em_project_id
  plan             = var.em_plan
  metro            = var.em_region
  operating_system = "talos_v1"
  billing_cycle    = "hourly"
  hostname         = "${var.cluster_name}-worker-${count.index}"
  count            = var.num_workers
}

# Configure and bootstrap Talos

resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = equinix_metal_device.talos_control_plane[*].access_public_ipv4
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${equinix_metal_reserved_ip_block.talos_control_plane_vip.network}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  count                       = length(equinix_metal_device.talos_control_plane)
  node                        = equinix_metal_device.talos_control_plane[count.index].access_public_ipv4
  config_patches = [
    templatefile("${path.module}/templates/vip.yaml.tmpl", {
      em_vip_ip    = equinix_metal_reserved_ip_block.talos_control_plane_vip.network
      em_api_token = var.em_api_token
    })
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${equinix_metal_reserved_ip_block.talos_control_plane_vip.network}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  count                       = length(equinix_metal_device.talos_worker)
  node                        = equinix_metal_device.talos_worker[count.index].access_public_ipv4
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = equinix_metal_device.talos_control_plane[0].access_public_ipv4
}

data "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = equinix_metal_device.talos_control_plane[0].access_public_ipv4
  wait                 = true
}
