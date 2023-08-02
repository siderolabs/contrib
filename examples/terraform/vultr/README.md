# Vultr Terraform Example

This example will create a load-balanced, HA Talos cluster on vultr.com.
It will use the marketplace image of Talos that is present in Vultr and should result in a stable, maintainable cluster.

## Prereqs

Export the `VULTR_API_KEY` environment variable with your API key obtained from vultr.com.
From this directory, issue `terraform init` to ensure the proper providers are pulled down.

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
This will create a cluster called `talos-vultr` with 3 control plane nodes and a single worker in the Atlanta region.
Each of these VMs will be 2 CPU / 4GB RAM VMs.
If different specs or regions are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.2.0 |
| <a name="requirement_vultr"></a> [vultr](#requirement\_vultr) | 2.12.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.2.0 |
| <a name="provider_vultr"></a> [vultr](#provider\_vultr) | 2.12.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/0.2.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.2.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker](https://registry.terraform.io/providers/siderolabs/talos/0.2.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/0.2.0/docs/resources/machine_secrets) | resource |
| [vultr_instance.talos_control_plane](https://registry.terraform.io/providers/vultr/vultr/2.12.0/docs/resources/instance) | resource |
| [vultr_instance.talos_workers](https://registry.terraform.io/providers/vultr/vultr/2.12.0/docs/resources/instance) | resource |
| [vultr_load_balancer.talos_lb](https://registry.terraform.io/providers/vultr/vultr/2.12.0/docs/resources/load_balancer) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.2.0/docs/data-sources/client_configuration) | data source |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/0.2.0/docs/data-sources/cluster_kubeconfig) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.2.0/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/0.2.0/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of cluster | `string` | `"talos-vultr"` | no |
| <a name="input_num_control_plane"></a> [num\_control\_plane](#input\_num\_control\_plane) | Number of control plane nodes to create | `number` | `3` | no |
| <a name="input_num_workers"></a> [num\_workers](#input\_num\_workers) | Number of worker nodes to create | `number` | `1` | no |
| <a name="input_vultr_plan"></a> [vultr\_plan](#input\_vultr\_plan) | Vultr plan to use | `string` | `"vc2-2c-4gb"` | no |
| <a name="input_vultr_region"></a> [vultr\_region](#input\_vultr\_region) | Vultr region to use | `string` | `"atl"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | n/a |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | n/a |
<!-- END_TF_DOCS -->