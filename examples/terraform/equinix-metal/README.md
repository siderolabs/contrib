# Equnix Metal Terraform Example

This example will create an HA Talos cluster on Equinix Metal.
It will use the built-in Talos offering that is present in Equnix Metal and should result in a stable, maintainable cluster.

## Prereqs

Export the `TF_VAR_em_api_token` environment variable with your API key obtained from Equinix Metal.
This environment variable will set the token for the Equinix Metal provider to function properly, as well as pass this token to Talos itself so that it can manage the VIP that is created for the cluster.
You can also enter this API token during the apply below.
From this directory, issue `terraform init` to ensure the proper providers are pulled down.

## Usage

Refer to [Boot Assets](https://www.talos.dev/latest/talos-guides/install/boot-assets/) on how to use [Image Factory](https://www.talos.dev/latest/learn-more/image-factory/) to customize the below mentioned Terraform variables

Change the version of `ipxe_script_url` to the version of Talos you want to use.
Change the `install_image` to the version of Talos you want to use.

To create a default cluster, this should be as simple as `terraform apply`.
This will create a cluster called `talos-em` with 3 control plane nodes and a single worker in the Washington DC region.
It will also create an elastic IP that is used
Each of these machines will their smallest offering, the `c3.small.x86`.
If different specs or regions are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_equinix"></a> [equinix](#requirement\_equinix) | 1.33.0 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_equinix"></a> [equinix](#provider\_equinix) | 1.33.0 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [equinix_metal_device.talos_control_plane_nodes](https://registry.terraform.io/providers/equinix/equinix/1.33.0/docs/resources/metal_device) | resource |
| [equinix_metal_device.talos_worker_group](https://registry.terraform.io/providers/equinix/equinix/1.33.0/docs/resources/metal_device) | resource |
| [equinix_metal_reserved_ip_block.talos_control_plane_vip](https://registry.terraform.io/providers/equinix/equinix/1.33.0/docs/resources/metal_reserved_ip_block) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker_group](https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/resources/machine_secrets) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/client_configuration) | data source |
| [talos_cluster_health.this](https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/cluster_health) | data source |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/cluster_kubeconfig) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker_group](https://registry.terraform.io/providers/siderolabs/talos/0.5.0/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of cluster | `string` | `"talos-em"` | no |
| <a name="input_config_patch_files"></a> [config\_patch\_files](#input\_config\_patch\_files) | Path to talos config path files that applies to all nodes | `list(string)` | `[]` | no |
| <a name="input_control_plane"></a> [control\_plane](#input\_control\_plane) | Info for control plane that will be created | <pre>object({<br>    plan               = optional(string, "c3.small.x86")<br>    ipxe_script_url    = optional(string, "https://pxe.factory.talos.dev/pxe/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.7.0/equinixMetal-amd64")<br>    install_image      = optional(string, "ghcr.io/talos-systems/installer:v1.7.0")<br>    num_instances      = optional(number, 3)<br>    config_patch_files = optional(list(string), [])<br>    tags               = optional(list(string), [])<br>  })</pre> | `{}` | no |
| <a name="input_em_api_token"></a> [em\_api\_token](#input\_em\_api\_token) | API token for Equinix Metal | `string` | n/a | yes |
| <a name="input_em_project_id"></a> [em\_project\_id](#input\_em\_project\_id) | Equinix Metal project ID | `string` | n/a | yes |
| <a name="input_em_region"></a> [em\_region](#input\_em\_region) | Equinix Metal region to use | `string` | `"dc"` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to add to the cluster cloud resources | `list(string)` | `[]` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version to use for the cluster, if not set the k8s version shipped with the talos sdk version will be used | `string` | `null` | no |
| <a name="input_talos_version_contract"></a> [talos\_version\_contract](#input\_talos\_version\_contract) | Talos API version to use for the cluster, if not set the the version shipped with the talos sdk version will be used | `string` | `null` | no |
| <a name="input_worker_groups"></a> [worker\_groups](#input\_worker\_groups) | List of node worker node groups to create | <pre>list(object({<br>    name               = string<br>    plan               = optional(string, "c3.small.x86")<br>    ipxe_script_url    = optional(string, "https://pxe.factory.talos.dev/pxe/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.7.0/equinixMetal-amd64")<br>    install_image      = optional(string, "ghcr.io/talos-systems/installer:v1.7.0")<br>    num_instances      = optional(number, 1)<br>    config_patch_files = optional(list(string), [])<br>    tags               = optional(list(string), [])<br>  }))</pre> | <pre>[<br>  {<br>    "name": "default"<br>  }<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | n/a |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | n/a |
<!-- END_TF_DOCS -->
