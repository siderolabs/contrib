locals {
  config_patches_common = [
    for path in var.config_patch_files : file(path)
  ]
}

resource "azurerm_resource_group" "this" {
  name     = var.cluster_name
  location = var.azure_location
  tags     = var.extra_tags
}

module "vnet" {
  source     = "Azure/network/azurerm"
  version    = "~> 5.0"
  depends_on = [azurerm_resource_group.this]

  vnet_name    = var.cluster_name
  use_for_each = true

  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_cidr
  subnet_prefixes     = cidrsubnets(var.vnet_cidr, 2)

  tags = var.extra_tags
}

module "control_plane_sg" {
  source     = "Azure/network-security-group/azurerm"
  version    = "~> 3.0"
  depends_on = [azurerm_resource_group.this]

  security_group_name   = var.cluster_name
  resource_group_name   = azurerm_resource_group.this.name
  source_address_prefix = [var.talos_api_allowed_cidr]

  custom_rules = [
    {
      name                   = "talos_api"
      priority               = "101"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      source_address_prefix  = var.talos_api_allowed_cidr
      destination_port_range = "50000"
    },
    {
      name                   = "kubernetes_api"
      priority               = "102"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      source_address_prefix  = var.kubernetes_api_allowed_cidr
      destination_port_range = "6443"
    },
  ]

  tags = var.extra_tags
}

module "kubernetes_api_lb" {
  source     = "Azure/loadbalancer/azurerm"
  version    = "~> 4.0"
  depends_on = [azurerm_resource_group.this]

  prefix              = var.cluster_name
  resource_group_name = azurerm_resource_group.this.name
  type                = "public"
  lb_sku              = "Standard"
  pip_sku             = "Standard"

  lb_port = {
    k8sapi = ["443", "Tcp", "6443"]
  }

  lb_probe = {
    k8sapi = ["Tcp", "6443", ""]
  }

  tags = var.extra_tags
}
module "talos_control_plane_nodes" {
  source     = "Azure/compute/azurerm"
  version    = "~> 5.0"
  depends_on = [azurerm_resource_group.this]

  resource_group_name           = azurerm_resource_group.this.name
  vm_hostname                   = "${var.cluster_name}-control-plane"
  enable_ssh_key                = false
  admin_password                = "mAk1ngp6ov1derH00py" // just to make the provider happy, talos doesn't use it
  nb_instances                  = var.control_plane.num_instances
  nb_public_ip                  = var.control_plane.num_instances
  public_ip_sku                 = "Standard"
  allocation_method             = "Static"
  vm_size                       = var.control_plane.vm_size
  vm_os_id                      = var.control_plane.vm_os_id
  delete_os_disk_on_termination = true
  storage_os_disk_size_gb       = 100
  vnet_subnet_id                = module.vnet.vnet_subnets[0]
  network_security_group        = { id = module.control_plane_sg.network_security_group_id }
  source_address_prefixes       = [var.talos_api_allowed_cidr]

  as_platform_fault_domain_count  = 3
  as_platform_update_domain_count = 5

  tags = var.extra_tags
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  count = var.control_plane.num_instances

  ip_configuration_name   = "${var.cluster_name}-control-plane-ip-${count.index}"
  backend_address_pool_id = module.kubernetes_api_lb.azurerm_lb_backend_address_pool_id
  network_interface_id    = module.talos_control_plane_nodes.network_interface_ids[count.index]
}

module "talos_worker_group" {
  source     = "Azure/compute/azurerm"
  version    = "~> 5.0"
  depends_on = [azurerm_resource_group.this]

  for_each = merge([for info in var.worker_groups : { "${info.name}" = info }]...)

  resource_group_name           = azurerm_resource_group.this.name
  vm_hostname                   = "${var.cluster_name}-worker-group-${each.key}"
  enable_ssh_key                = false
  admin_password                = "mAk1ngp6ov1derH00py" // just to make the provider happy, talos doesn't use it
  nb_instances                  = each.value.num_instances
  nb_public_ip                  = each.value.num_instances
  vm_size                       = each.value.vm_size
  vm_os_id                      = each.value.vm_os_id
  delete_os_disk_on_termination = true
  storage_os_disk_size_gb       = 100
  vnet_subnet_id                = module.vnet.vnet_subnets[0]
  remote_port                   = "50000"
  source_address_prefixes       = [var.talos_api_allowed_cidr]

  as_platform_fault_domain_count  = 3
  as_platform_update_domain_count = 5

  tags = var.extra_tags
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${module.kubernetes_api_lb.azurerm_public_ip_address[0]}"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches = concat(
    local.config_patches_common,
    [for path in var.control_plane.config_patch_files : file(path)]
  )
}

data "talos_machine_configuration" "worker_group" {
  for_each = merge([for info in var.worker_groups : { "${info.name}" = info }]...)

  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${module.kubernetes_api_lb.azurerm_public_ip_address[0]}"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches = concat(
    local.config_patches_common,
    [for path in each.value.config_patch_files : file(path)]
  )
}

resource "talos_machine_configuration_apply" "controlplane" {
  count = var.control_plane.num_instances

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  endpoint                    = module.talos_control_plane_nodes.public_ip_address[count.index]
  node                        = module.talos_control_plane_nodes.network_interface_private_ip[count.index]
}

resource "talos_machine_configuration_apply" "worker_group" {
  for_each = merge([
    for info in var.worker_groups : {
      for index in range(0, info.num_instances) :
      "${info.name}.${index}" => {
        name       = info.name,
        public_ip  = module.talos_worker_group[info.name].public_ip_address[index],
        private_ip = module.talos_worker_group[info.name].network_interface_private_ip[index]
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
  endpoint             = module.talos_control_plane_nodes.public_ip_address[0]
  node                 = module.talos_control_plane_nodes.network_interface_private_ip[0]
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = module.talos_control_plane_nodes.public_ip_address
  nodes                = flatten([module.talos_control_plane_nodes.network_interface_private_ip, flatten([for node in module.talos_worker_group : node.network_interface_private_ip])])
}

data "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = module.talos_control_plane_nodes.public_ip_address[0]
  node                 = module.talos_control_plane_nodes.network_interface_private_ip[0]
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker_group,
    data.talos_cluster_kubeconfig.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = flatten(module.talos_control_plane_nodes.*.public_ip_address)
  control_plane_nodes  = flatten(module.talos_control_plane_nodes.*.network_interface_private_ip)
  worker_nodes         = flatten([for node in module.talos_worker_group : node.network_interface_private_ip])
}
