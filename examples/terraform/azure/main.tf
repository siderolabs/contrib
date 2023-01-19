resource "azurerm_resource_group" "this" {
  name     = var.cluster_name
  location = var.azure_location
}

resource "azurerm_storage_account" "this" {
  depends_on = [azurerm_resource_group.this]

  name                     = replace(lower(var.cluster_name), "/[^0-9a-z]/", "") 
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "this" {
  depends_on = [azurerm_storage_account.this]

  name                  = var.cluster_name
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "this" {
  depends_on = [azurerm_resource_group.this]

  name                    = "${var.cluster_name}.vhd"
  storage_account_name    = azurerm_storage_account.this.name
  storage_container_name  = azurerm_storage_container.this.name
  type                    = "Page"
  source                  = var.image_file  
}

resource "azurerm_image" "this" {
  depends_on = [azurerm_storage_blob.this]

  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = azurerm_storage_blob.this.url
  }
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
}

module "talos_control_plane_nodes" {
  source     = "Azure/compute/azurerm"
  version    = "~> 5.0"
  depends_on = [azurerm_resource_group.this]

  resource_group_name     = azurerm_resource_group.this.name
  vm_hostname             = "${var.cluster_name}-control-plane"
  nb_instances            = var.num_control_planes
  nb_public_ip            = var.num_control_planes
  public_ip_sku           = "Standard"
  allocation_method       = "Static"
  vm_size                 = var.vm_size
  vm_os_id                = azurerm_image.this.id
  storage_os_disk_size_gb = 100
  vnet_subnet_id          = module.vnet.vnet_subnets[0]
  network_security_group  = {id = module.control_plane_sg.network_security_group_id}
  source_address_prefixes = [var.talos_api_allowed_cidr]

  as_platform_fault_domain_count  = 3
  as_platform_update_domain_count = 5
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  count = var.num_control_planes

  ip_configuration_name   = "${var.cluster_name}-control-plane-ip-${count.index}"
  backend_address_pool_id = module.kubernetes_api_lb.azurerm_lb_backend_address_pool_id
  network_interface_id    = module.talos_control_plane_nodes.network_interface_ids[count.index]
}

module "talos_worker_nodes" {
  source     = "Azure/compute/azurerm"
  version    = "~> 5.0"
  depends_on = [azurerm_resource_group.this]

  resource_group_name     = azurerm_resource_group.this.name
  vm_hostname             = "${var.cluster_name}-worker"
  nb_instances            = var.num_workers
  nb_public_ip            = var.num_workers
  vm_size                 = var.vm_size
  vm_os_id                = azurerm_image.this.id
  storage_os_disk_size_gb = 100
  vnet_subnet_id          = module.vnet.vnet_subnets[0]
  remote_port             = "50000"
  source_address_prefixes = [var.talos_api_allowed_cidr]

  as_platform_fault_domain_count  = 3
  as_platform_update_domain_count = 5
}

resource "talos_machine_secrets" "this" {}

resource "talos_machine_configuration_controlplane" "this" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${module.kubernetes_api_lb.azurerm_public_ip_address[0]}"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_machine_configuration_worker" "this" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${module.kubernetes_api_lb.azurerm_public_ip_address[0]}"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

resource "talos_client_configuration" "this" {
  cluster_name    = var.cluster_name
  machine_secrets = talos_machine_secrets.this.machine_secrets
  endpoints       = module.talos_control_plane_nodes.public_ip_address
  nodes           = flatten([module.talos_control_plane_nodes.network_interface_private_ip, module.talos_worker_nodes.network_interface_private_ip])
}

resource "talos_machine_configuration_apply" "controlplane" {
  count = var.num_control_planes

  talos_config          = talos_client_configuration.this.talos_config
  machine_configuration = talos_machine_configuration_controlplane.this.machine_config
  endpoint              = module.talos_control_plane_nodes.public_ip_address[count.index]
  node                  = module.talos_control_plane_nodes.network_interface_private_ip[count.index]
}

resource "talos_machine_configuration_apply" "worker" {
  count = var.num_workers

  talos_config          = talos_client_configuration.this.talos_config
  machine_configuration = talos_machine_configuration_worker.this.machine_config
  endpoint              = module.talos_worker_nodes.public_ip_address[count.index]
  node                  = module.talos_worker_nodes.network_interface_private_ip[count.index]
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  talos_config = talos_client_configuration.this.talos_config
  endpoint      = module.talos_control_plane_nodes.public_ip_address[0]
  node          = module.talos_control_plane_nodes.network_interface_private_ip[0]
}

resource "talos_cluster_kubeconfig" "this" {
  talos_config = talos_client_configuration.this.talos_config
  endpoint      = module.talos_control_plane_nodes.public_ip_address[0]
  node          = module.talos_control_plane_nodes.network_interface_private_ip[0]
}
