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

resource "talos_machine_secrets" "this" {}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = vultr_instance.talos_control_plane[*].main_ip
}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${vultr_load_balancer.talos_lb.ipv4}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  count                       = length(vultr_instance.talos_control_plane)
  node                        = vultr_instance.talos_control_plane[count.index].main_ip
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${vultr_load_balancer.talos_lb.ipv4}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  count                       = length(vultr_instance.talos_workers)
  node                        = vultr_instance.talos_workers[count.index].main_ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = vultr_instance.talos_control_plane[0].main_ip
}

data "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = vultr_instance.talos_control_plane[0].main_ip
}
