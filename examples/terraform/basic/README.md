# Basic Terraform Example

This example will create a basic Talos cluster using local machines.

## Prereqs

This guide assumes that you have pre-existing machines that have been booted with a Talos image or ISO without machine configuration, such that these machines are sitting in "maintenance mode" waiting to be provisioned.
From this directory, issue `terraform init` to ensure the proper providers are pulled down.

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
You will need to specify the `cluster_name` and `cluster_endpoint` variables during application.
The `cluster_endpoint` variable should have the form `https://<control-plane-ip-or-vip-or-dns-name>:6443`.
This will create a cluster based on the `node_data` variable, containing the IPs of each Talos node, as well as the install disk and hostname (optional).

If different configurations are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.6.0-beta.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.6.0-beta.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/0.6.0-beta.0/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/0.6.0-beta.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.6.0-beta.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker](https://registry.terraform.io/providers/siderolabs/talos/0.6.0-beta.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/0.6.0-beta.0/docs/resources/machine_secrets) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.6.0-beta.0/docs/data-sources/client_configuration) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.6.0-beta.0/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/0.6.0-beta.0/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | The endpoint for the Talos cluster | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | A name to provide for the Talos cluster | `string` | n/a | yes |
| <a name="input_node_data"></a> [node\_data](#input\_node\_data) | A map of node data | <pre>object({<br/>    controlplanes = map(object({<br/>      install_disk = string<br/>      hostname     = optional(string)<br/>    }))<br/>    workers = map(object({<br/>      install_disk = string<br/>      hostname     = optional(string)<br/>    }))<br/>  })</pre> | <pre>{<br/>  "controlplanes": {<br/>    "10.5.0.2": {<br/>      "install_disk": "/dev/sda"<br/>    },<br/>    "10.5.0.3": {<br/>      "install_disk": "/dev/sda"<br/>    },<br/>    "10.5.0.4": {<br/>      "install_disk": "/dev/sda"<br/>    }<br/>  },<br/>  "workers": {<br/>    "10.5.0.5": {<br/>      "hostname": "worker-1",<br/>      "install_disk": "/dev/nvme0n1"<br/>    },<br/>    "10.5.0.6": {<br/>      "hostname": "worker-2",<br/>      "install_disk": "/dev/nvme0n1"<br/>    }<br/>  }<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | n/a |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | n/a |
<!-- END_TF_DOCS -->