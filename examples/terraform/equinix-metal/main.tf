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

resource "talos_machine_secrets" "machine_secrets" {}

resource "talos_client_configuration" "talosconfig" {
  cluster_name    = var.cluster_name
  machine_secrets = talos_machine_secrets.machine_secrets.machine_secrets
  endpoints       = equinix_metal_device.talos_control_plane[*].access_public_ipv4
}

resource "talos_machine_configuration_controlplane" "machineconfig_cp" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${equinix_metal_reserved_ip_block.talos_control_plane_vip.network}:6443"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  talos_config          = talos_client_configuration.talosconfig.talos_config
  machine_configuration = talos_machine_configuration_controlplane.machineconfig_cp.machine_config
  count                 = length(equinix_metal_device.talos_control_plane)
  endpoint              = equinix_metal_device.talos_control_plane[count.index].access_public_ipv4
  node                  = equinix_metal_device.talos_control_plane[count.index].access_public_ipv4
  config_patches = [
    templatefile("${path.module}/templates/vip.yaml.tmpl", {
      em_vip_ip    = equinix_metal_reserved_ip_block.talos_control_plane_vip.network
      em_api_token = var.em_api_token
    })
  ]
}

resource "talos_machine_configuration_controlplane" "machineconfig_worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${equinix_metal_reserved_ip_block.talos_control_plane_vip.network}:6443"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  talos_config          = talos_client_configuration.talosconfig.talos_config
  machine_configuration = talos_machine_configuration_controlplane.machineconfig_worker.machine_config
  count                 = length(equinix_metal_device.talos_worker)
  endpoint              = equinix_metal_device.talos_worker[count.index].access_public_ipv4
  node                  = equinix_metal_device.talos_worker[count.index].access_public_ipv4
}

resource "talos_machine_bootstrap" "bootstrap" {
  talos_config = talos_client_configuration.talosconfig.talos_config
  endpoint     = equinix_metal_device.talos_control_plane[0].access_public_ipv4
  node         = equinix_metal_device.talos_control_plane[0].access_public_ipv4
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  talos_config = talos_client_configuration.talosconfig.talos_config
  endpoint     = equinix_metal_device.talos_control_plane[0].access_public_ipv4
  node         = equinix_metal_device.talos_control_plane[0].access_public_ipv4
}
