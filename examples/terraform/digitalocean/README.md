# Digitalocean Terraform Example

This example will create a load-balanced, HA Talos cluster on Digitalocean.
It will upload the specified Talos release as a custom image and should result in a stable, maintainable cluster.

## Prereqs

Export the `DIGITALOCEAN_TOKEN` environment variable with your API key obtained from digitalocean.com.
From this directory, issue `terraform init` to ensure the proper providers are pulled down.

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
This will create a cluster called `talos-do` with 3 control plane nodes and a single worker in the NYC3 region.
Each of these VMs will be 2 CPU / 4GB RAM VMs.
If different specs or regions are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_digitalocean"></a> [digitalocean](#requirement\_digitalocean) | 2.28.0 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.8.0-alpha.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_digitalocean"></a> [digitalocean](#provider\_digitalocean) | 2.28.0 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.8.0-alpha.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.6 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [digitalocean_custom_image.talos_custom_image](https://registry.terraform.io/providers/digitalocean/digitalocean/2.28.0/docs/resources/custom_image) | resource |
| [digitalocean_droplet.talos_control_plane](https://registry.terraform.io/providers/digitalocean/digitalocean/2.28.0/docs/resources/droplet) | resource |
| [digitalocean_droplet.talos_workers](https://registry.terraform.io/providers/digitalocean/digitalocean/2.28.0/docs/resources/droplet) | resource |
| [digitalocean_loadbalancer.talos_lb](https://registry.terraform.io/providers/digitalocean/digitalocean/2.28.0/docs/resources/loadbalancer) | resource |
| [digitalocean_ssh_key.fake_ssh_key](https://registry.terraform.io/providers/digitalocean/digitalocean/2.28.0/docs/resources/ssh_key) | resource |
| [talos_machine_bootstrap.bootstrap](https://registry.terraform.io/providers/siderolabs/talos/0.8.0-alpha.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.cp_config_apply](https://registry.terraform.io/providers/siderolabs/talos/0.8.0-alpha.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker_config_apply](https://registry.terraform.io/providers/siderolabs/talos/0.8.0-alpha.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.machine_secrets](https://registry.terraform.io/providers/siderolabs/talos/0.8.0-alpha.0/docs/resources/machine_secrets) | resource |
| [tls_private_key.fake_ssh_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [talos_client_configuration.talosconfig](https://registry.terraform.io/providers/siderolabs/talos/0.8.0-alpha.0/docs/data-sources/client_configuration) | data source |
| [talos_cluster_kubeconfig.kubeconfig](https://registry.terraform.io/providers/siderolabs/talos/0.8.0-alpha.0/docs/data-sources/cluster_kubeconfig) | data source |
| [talos_machine_configuration.machineconfig_cp](https://registry.terraform.io/providers/siderolabs/talos/0.8.0-alpha.0/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.machineconfig_worker](https://registry.terraform.io/providers/siderolabs/talos/0.8.0-alpha.0/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of cluster | `string` | `"talos-do"` | no |
| <a name="input_do_plan_control_plane"></a> [do\_plan\_control\_plane](#input\_do\_plan\_control\_plane) | DO plan to use for control plane nodes | `string` | `"s-2vcpu-4gb"` | no |
| <a name="input_do_plan_worker"></a> [do\_plan\_worker](#input\_do\_plan\_worker) | DO plan to use for worker nodes | `string` | `"s-2vcpu-4gb"` | no |
| <a name="input_do_region"></a> [do\_region](#input\_do\_region) | DO region to use | `string` | `"nyc3"` | no |
| <a name="input_num_control_plane"></a> [num\_control\_plane](#input\_num\_control\_plane) | Number of control plane nodes to create | `number` | `3` | no |
| <a name="input_num_workers"></a> [num\_workers](#input\_num\_workers) | Number of worker nodes to create | `number` | `1` | no |
| <a name="input_talos_version"></a> [talos\_version](#input\_talos\_version) | Talos version to deploy | `string` | `"v1.4.0"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | n/a |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | n/a |
<!-- END_TF_DOCS -->