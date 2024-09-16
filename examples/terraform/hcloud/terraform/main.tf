# create the private network
resource "hcloud_network" "network" {
  name     = var.private_network_name
  ip_range = "10.0.0.0/24"
}

resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.network.id
  type         = "cloud"
  network_zone = var.network_zone
  ip_range     = var.private_network_subnet_range
}

# create the load balancer
resource "hcloud_load_balancer" "controlplane_load_balancer" {
  name               = "talos-lb"
  load_balancer_type = var.load_balancer_type
  network_zone       = var.network_zone
}

# attach the load blanacer to the private network
resource "hcloud_load_balancer_network" "srvnetwork" {
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  network_id       = hcloud_network.network.id
}

# at the control plane to the load balancer
resource "hcloud_load_balancer_target" "load_balancer_target" {
  type             = "server"
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  server_id        = hcloud_server.controlplane_server.id
  use_private_ip   = true
  depends_on = [
    hcloud_server.controlplane_server
  ]
}

# loadblance kubectl port
resource "hcloud_load_balancer_service" "controlplane_load_balancer_service_kubectl" {
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  protocol         = "tcp"
  listen_port      = 6443
  destination_port = 6443
}

# loadbalance talosctl
resource "hcloud_load_balancer_service" "controlplane_load_balancer_service_talosctl" {
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  protocol         = "tcp"
  listen_port      = 50000
  destination_port = 50000
}

# loadbalance mayastor
resource "hcloud_load_balancer_service" "controlplane_load_balancer_service_mayastor" {
  load_balancer_id = hcloud_load_balancer.controlplane_load_balancer.id
  protocol         = "tcp"
  listen_port      = 30011
  destination_port = 30011
}


# Talos
# create the machine secrets
resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version_contract
}

# create the controlplane config, using the loadbalancer as cluster endpoint
data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${hcloud_load_balancer.controlplane_load_balancer.ipv4}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  config_patches = [
    templatefile("${path.module}/templates/controlplanepatch.yaml.tmpl", {
      loadbalancerip = hcloud_load_balancer.controlplane_load_balancer.ipv4, subnet = var.private_network_subnet_range
    })
  ]
  depends_on = [
    hcloud_load_balancer.controlplane_load_balancer
  ]
}

# create the talos client config
data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints = [
    hcloud_load_balancer.controlplane_load_balancer.ipv4
  ]
}

# create the control plane and apply generated config in user_data
resource "hcloud_server" "controlplane_server" {
  name        = "talos-controlplane"
  image       = var.image_id
  server_type = var.controlplane_type
  location    = var.location
  labels      = { type = "talos-controlplane" }
  user_data   = data.talos_machine_configuration.controlplane.machine_configuration
  network {
    network_id = hcloud_network.network.id
    ip         = var.controlplane_ip
  }
  depends_on = [
    hcloud_network_subnet.subnet,
    hcloud_load_balancer.controlplane_load_balancer,
    talos_machine_secrets.this,
  ]
}

# bootstrap the cluster
resource "talos_machine_bootstrap" "bootstrap" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = hcloud_server.controlplane_server.ipv4_address
  node                 = hcloud_server.controlplane_server.ipv4_address
}

# create the worker config and apply the worker patch
data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${hcloud_load_balancer.controlplane_load_balancer.ipv4}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  config_patches = [
    templatefile("${path.module}/templates/workerpatch.yaml.tmpl", {
      subnet = var.private_network_subnet_range
    })
  ]
  depends_on = [
    hcloud_load_balancer.controlplane_load_balancer
  ]
}

# create the worker and apply the generated config in user_data
resource "hcloud_server" "worker_server" {
  for_each    = var.workers
  name        = each.value.name
  image       = var.image_id
  server_type = each.value.server_type
  location    = each.value.location
  labels      = { type = "talos-worker" }
  user_data   = data.talos_machine_configuration.worker.machine_configuration
  network {
    network_id = hcloud_network.network.id
  }
  depends_on = [
    hcloud_network_subnet.subnet,
    hcloud_load_balancer.controlplane_load_balancer,
  ]
}

# create the extra ssd volumes and attach them to the worker
resource "hcloud_volume" "volumes" {
  for_each  = hcloud_server.worker_server
  name      = "${each.value.name}-volume"
  size      = var.worker_extra_volume_size
  server_id = each.value.id
  depends_on = [
    hcloud_server.worker_server
  ]
}

# kubeconfig
resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = hcloud_server.controlplane_server.ipv4_address
}
