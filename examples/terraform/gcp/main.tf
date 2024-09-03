data "google_compute_zones" "available" {}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.1"

  project_id   = var.project
  network_name = var.cluster_name

  subnets = [
    {
      subnet_name   = "main"
      subnet_ip     = var.vpc_cidr
      subnet_region = var.region
    }
  ]

  egress_rules = [
    {
      name        = "allow-egress"
      description = "Allow all egress traffic"
      priority    = 999
      allow = [
        {
          protocol = "all"
        }
      ]
      destination_ranges = ["0.0.0.0/0"]
    }
  ]

  ingress_rules = [
    {
      name        = "allow-internal"
      description = "Allow all internal traffic"
      priority    = 65534
      allow = [
        {
          protocol = "all"
        }
      ]
      source_ranges = [var.vpc_cidr]
    },
    {
      name        = "allow-icmp"
      description = "Allow ICMP from anywhere"
      priority    = 65534
      allow = [
        {
          protocol = "icmp"
        }
      ]
      source_ranges = ["0.0.0.0/0"]
    }
  ]
}

resource "google_compute_instance_group" "talos-cp-ig" {
  name        = "${var.cluster_name}-cp-ig"
  description = "Talos Control Plane Instance Group"
  zone        = var.zone
  network     = module.vpc.network_self_link
  named_port {
    name = "tcp6443"
    port = 6443
  }
}

resource "google_compute_health_check" "this" {
  name = "${var.cluster_name}-cp-hc"
  tcp_health_check {
    port = 6443
  }
}

resource "google_compute_backend_service" "this" {
  name = "${var.cluster_name}-cp-bs"
  backend {
    group = google_compute_instance_group.talos-cp-ig.id
  }
  health_checks = [google_compute_health_check.this.id]
  port_name     = "tcp6443"
  protocol      = "TCP"
  timeout_sec   = 300
}

resource "google_compute_target_tcp_proxy" "this" {
  name            = "${var.cluster_name}-cp-tcp-proxy"
  backend_service = google_compute_backend_service.this.id
  proxy_header    = "NONE"
}

resource "google_compute_global_address" "this" {
  name = "${var.cluster_name}-cp-address"
}

resource "google_compute_global_forwarding_rule" "this" {
  name        = "${var.cluster_name}-cp-forwarding-rule"
  target      = google_compute_target_tcp_proxy.this.id
  port_range  = "443"
  ip_protocol = "TCP"
  ip_address  = google_compute_global_address.this.id
}

data "google_netblock_ip_ranges" "this" {
  range_type = "health-checkers"
}

resource "google_compute_firewall" "health-check" {
  name    = "${var.cluster_name}-cp-health-check"
  network = module.vpc.network_name
  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }
  source_ranges = data.google_netblock_ip_ranges.this.cidr_blocks_ipv4
  target_tags   = ["talos-api"]
}

resource "google_compute_firewall" "talos-api" {
  name    = "${var.cluster_name}-talos-api"
  network = module.vpc.network_name
  allow {
    protocol = "tcp"
    ports    = ["50000"]
  }
  source_ranges = [var.talos_api_allowed_cidr]
  target_tags   = ["talos-api"]
}

resource "google_compute_instance" "cp" {
  count        = var.control_plane.num_instances
  name         = "${var.cluster_name}-cp-${count.index}"
  machine_type = var.control_plane.instance_type
  tags         = ["talos-api"]
  boot_disk {
    initialize_params {
      image = var.control_plane.image
    }
  }
  network_interface {
    subnetwork = module.vpc.subnets[keys(module.vpc.subnets)[0]].self_link
    access_config {
      network_tier = "PREMIUM"
    }
  }
}

resource "google_compute_instance" "workers" {
  for_each = merge([for info in var.worker_groups : { for index in range(0, info.num_instances) : "${info.name}.${index}" => info }]...)

  name         = "${var.cluster_name}-worker-group-${each.value.name}-${trimprefix(each.key, "${each.value.name}.")}"
  machine_type = each.value.instance_type
  tags         = ["talos-api"]
  boot_disk {
    initialize_params {
      image = each.value.image == null ? var.control_plane.image : each.value.image
    }
  }
  network_interface {
    subnetwork = module.vpc.subnets[keys(module.vpc.subnets)[0]].self_link
    access_config {
      network_tier = "PREMIUM"
    }
  }
}

resource "google_compute_instance_group_membership" "this" {
  count          = var.control_plane.num_instances
  instance       = google_compute_instance.cp[count.index].self_link
  instance_group = google_compute_instance_group.talos-cp-ig.self_link
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${google_compute_global_forwarding_rule.this.ip_address}"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches = concat(
    [for path in var.control_plane.config_patch_files : file(path)]
  )
}

data "talos_machine_configuration" "worker_group" {
  for_each = merge([for info in var.worker_groups : { "${info.name}" = info }]...)

  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${google_compute_global_forwarding_rule.this.ip_address}"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches = concat(
    [for path in each.value.config_patch_files : file(path)]
  )
}

resource "talos_machine_configuration_apply" "controlplane" {
  depends_on = [
    google_compute_firewall.health-check,
    google_compute_firewall.talos-api,
  ]

  count = var.control_plane.num_instances

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  endpoint                    = google_compute_instance.cp[count.index].network_interface[0].access_config[0].nat_ip
  node                        = google_compute_instance.cp[count.index].network_interface[0].access_config[0].nat_ip
}

resource "talos_machine_configuration_apply" "worker_group" {
  depends_on = [
    google_compute_firewall.health-check,
    google_compute_firewall.talos-api,
  ]

  for_each = merge([
    for info in var.worker_groups : {
      for index in range(0, info.num_instances) :
      "${info.name}.${index}" => {
        name       = info.name,
        public_ip  = google_compute_instance.workers["${info.name}.${index}"].network_interface[0].access_config[0].nat_ip,
        private_ip = google_compute_instance.workers["${info.name}.${index}"].network_interface[0].network_ip
      }
    }
  ]...)

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker_group[each.value.name].machine_configuration
  endpoint                    = each.value.public_ip
  node                        = each.value.public_ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = google_compute_instance.cp[0].network_interface[0].access_config[0].nat_ip
  node                 = google_compute_instance.cp[0].network_interface[0].access_config[0].nat_ip
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for interface in google_compute_instance.cp.*.network_interface : interface[0].access_config[0].nat_ip]
  nodes = concat(
    [for interface in google_compute_instance.cp.*.network_interface : interface[0].access_config[0].nat_ip],
    [for instance in google_compute_instance.workers : instance.network_interface[0].network_ip],
  )
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = google_compute_instance.cp[0].network_interface[0].access_config[0].nat_ip
  node                 = google_compute_instance.cp[0].network_interface[0].access_config[0].nat_ip
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker_group,
    talos_cluster_kubeconfig.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for interface in google_compute_instance.cp.*.network_interface : interface[0].access_config[0].nat_ip]
  control_plane_nodes  = [for interface in google_compute_instance.cp.*.network_interface : interface[0].network_ip]
  worker_nodes         = [for instance in google_compute_instance.workers : instance.network_interface[0].network_ip]
}
