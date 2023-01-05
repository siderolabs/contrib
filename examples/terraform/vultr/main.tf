# TF setup

terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
      version = "2.12.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.1.0"
    }
  }
}

# Configure providers

provider "vultr" {}

provider "talos" {}

# Create all instances
resource "vultr_instance" "talos_control_plane" {
  plan     = var.vultr_plan
  region   = var.vultr_region
  image_id = "talos-linux"
  hostname = "${var.cluster_name}-control-plane-${count.index}"
  label    = "${var.cluster_name}-control-plane-${count.index}"
  count    = var.num_control_plane
}

resource "vultr_instance" "talos_workers" {
  plan     = var.vultr_plan
  region   = var.vultr_region
  image_id = "talos-linux"
  hostname = "${var.cluster_name}-worker-${count.index}"
  label    = "${var.cluster_name}-worker-${count.index}"
  count    = var.num_workers
}

# LB for control plane
resource "vultr_load_balancer" "talos_lb" {
  region              = var.vultr_region
  label               = "${var.cluster_name}-k8s"
  balancing_algorithm = "roundrobin"
  attached_instances  = vultr_instance.talos_control_plane[*].id
  forwarding_rules {
    frontend_protocol = "tcp"
    frontend_port     = 6443
    backend_protocol  = "tcp"
    backend_port      = 6443
  }
  health_check {
    port                = 6443
    protocol            = "tcp"
    response_timeout    = 1
    unhealthy_threshold = 2
    check_interval      = 3
    healthy_threshold   = 4
  }
}

resource "talos_machine_secrets" "machine_secrets" {}

resource "talos_client_configuration" "talosconfig" {
  cluster_name    = var.cluster_name
  machine_secrets = talos_machine_secrets.machine_secrets.machine_secrets
  endpoints       = vultr_instance.talos_control_plane[*].main_ip
}

resource "talos_machine_configuration_controlplane" "machineconfig_cp" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${vultr_load_balancer.talos_lb.ipv4}:6443"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  depends_on       = [vultr_load_balancer.talos_lb]
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  talos_config          = talos_client_configuration.talosconfig.talos_config
  machine_configuration = talos_machine_configuration_controlplane.machineconfig_cp.machine_config
  count                 = length(vultr_instance.talos_control_plane)
  endpoint              = vultr_instance.talos_control_plane[count.index].main_ip
  node                  = vultr_instance.talos_control_plane[count.index].main_ip
}

resource "talos_machine_configuration_worker" "machineconfig_worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${vultr_load_balancer.talos_lb.ipv4}:6443"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
  depends_on       = [vultr_load_balancer.talos_lb]
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  talos_config          = talos_client_configuration.talosconfig.talos_config
  machine_configuration = talos_machine_configuration_worker.machineconfig_worker.machine_config
  count                 = length(vultr_instance.talos_workers)
  endpoint              = vultr_instance.talos_workers[count.index].main_ip
  node                  = vultr_instance.talos_workers[count.index].main_ip
}

resource "talos_machine_bootstrap" "bootstrap" {
  talos_config = talos_client_configuration.talosconfig.talos_config
  endpoint     = vultr_instance.talos_control_plane[0].main_ip
  node         = vultr_instance.talos_control_plane[0].main_ip
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  talos_config = talos_client_configuration.talosconfig.talos_config
  endpoint     = vultr_instance.talos_control_plane[0].main_ip
  node         = vultr_instance.talos_control_plane[0].main_ip
}
