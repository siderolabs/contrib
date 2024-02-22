# Azure Terraform Example

This example will create a load-balanced, HA Talos cluster on Azure.
It will use the official Sidero Labs AMI of Talos that is present and should result in a stable, maintainable cluster.

## Prereqs

Ensure your Azure environment is configured correctly (see  for details).
From this directory, issue `terraform init` to ensure the proper providers are pulled down.
A disk image of Talos must be downloaded locally to be provided as a storage blob in Azure.
The following command is an example og how to do this for the latest relase of Talos:

```bash
curl -sL https://github.com/siderolabs/talos/releases/latest/download/azure-amd64.tar.gz | tar -xz
```

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
Occasionally some Azure resources may not be ready in time for Terraform to rely on them for a later resource and may return errors such as the following:

```shell
 Error: failed creating container: failed creating container: containers.Client#Create: Failure responding to request: StatusCode=404 -- Original Error: autorest/azure: Service returned an error. Status=404 Code="ResourceNotFound" Message="The specified resource does not exist.\nRequestId:d7008d74-b01e-007b-39d8-2c38de000000\nTime:2023-01-20T14:05:32.3698226Z"

   with azurerm_storage_container.this,
   on main.tf line 16, in resource "azurerm_storage_container" "this":
   16: resource "azurerm_storage_container" "this" {
```

Simply re-run `terraform apply` to solve these issues.

This will create a cluster called `talos-azure-example` with 3 control plane nodes and a single worker in the West Europe region.
By default, the instances will be `Standard_B2s`, with 2 VPU and 4GB RAM each.
If different specs or regions are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.0 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.3.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.92.0 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.3.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_control_plane_sg"></a> [control\_plane\_sg](#module\_control\_plane\_sg) | Azure/network-security-group/azurerm | ~> 3.0 |
| <a name="module_kubernetes_api_lb"></a> [kubernetes\_api\_lb](#module\_kubernetes\_api\_lb) | Azure/loadbalancer/azurerm | ~> 4.0 |
| <a name="module_talos_control_plane_nodes"></a> [talos\_control\_plane\_nodes](#module\_talos\_control\_plane\_nodes) | Azure/compute/azurerm | ~> 5.0 |
| <a name="module_talos_worker_nodes"></a> [talos\_worker\_nodes](#module\_talos\_worker\_nodes) | Azure/compute/azurerm | ~> 5.0 |
| <a name="module_vnet"></a> [vnet](#module\_vnet) | Azure/network/azurerm | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_image.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/image) | resource |
| [azurerm_network_interface_backend_address_pool_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_backend_address_pool_association) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_storage_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_blob.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_blob) | resource |
| [azurerm_storage_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/0.3.2/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.3.2/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker](https://registry.terraform.io/providers/siderolabs/talos/0.3.2/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/0.3.2/docs/resources/machine_secrets) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.3.2/docs/data-sources/client_configuration) | data source |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/0.3.2/docs/data-sources/cluster_kubeconfig) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.3.2/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/0.3.2/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_azure_location"></a> [azure\_location](#input\_azure\_location) | Azure location to use | `string` | `"West Europe"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of cluster | `string` | `"talos-azure-example"` | no |
| <a name="input_image_file"></a> [image\_file](#input\_image\_file) | Path to the Talos image file to be used for the virtual machines | `string` | `"./disk.vhd"` | no |
| <a name="input_kubernetes_api_allowed_cidr"></a> [kubernetes\_api\_allowed\_cidr](#input\_kubernetes\_api\_allowed\_cidr) | The CIDR from which to allow to access the Kubernetes API | `string` | `"0.0.0.0/0"` | no |
| <a name="input_num_control_planes"></a> [num\_control\_planes](#input\_num\_control\_planes) | Number of control plane nodes to create | `number` | `3` | no |
| <a name="input_num_workers"></a> [num\_workers](#input\_num\_workers) | Number of worker nodes to create | `number` | `1` | no |
| <a name="input_talos_api_allowed_cidr"></a> [talos\_api\_allowed\_cidr](#input\_talos\_api\_allowed\_cidr) | The CIDR from which to allow to access the Talos API | `string` | `"0.0.0.0/0"` | no |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | VM size to use for the nodes | `string` | `"Standard_B2s"` | no |
| <a name="input_vnet_cidr"></a> [vnet\_cidr](#input\_vnet\_cidr) | The IPv4 CIDR block for the Virtual Network. | `string` | `"172.16.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | n/a |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | n/a |
<!-- END_TF_DOCS -->