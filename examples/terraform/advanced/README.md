# Advanced Terraform Example

This example will create a local Talos cluster using libvirt.

This example shows how to manage the whole Talos machine secrets using custom CA.
It's recommended to pre-generate the keys required and pass it as variables to Terraform, since terraform stores the state in plain text.

## Prereqs

This guide assumes that libvirt is installed and running.
From this directory, issue `terraform init` to ensure the proper providers are pulled down.

## Usage

To create a default cluster, this should be as simple as `terraform apply`.
You will need to specify the `cluster_name` and `iso_path` variables during application.

If different configurations are required, override them through command line with the `-var` flag or by creating a varsfile and overriding with `-var-file`.
Destroying the cluster should, again, be a simple `terraform destroy`.

Getting the kubeconfig and talosconfig for this cluster can be done with `terraform output -raw kubeconfig > <desired-path-and-filename>` and `terraform output -raw talosconfig > <desired-path-and-filename>`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_libvirt"></a> [libvirt](#requirement\_libvirt) | 0.7.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.5.1 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.9.0-alpha.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 4.0.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_libvirt"></a> [libvirt](#provider\_libvirt) | 0.7.1 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.5.1 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.9.0-alpha.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bootstrap_token"></a> [bootstrap\_token](#module\_bootstrap\_token) | ./modules/bootstrap_token | n/a |
| <a name="module_trustdinfo_token"></a> [trustdinfo\_token](#module\_trustdinfo\_token) | ./modules/bootstrap_token | n/a |

## Resources

| Name | Type |
|------|------|
| [libvirt_domain.cp](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.1/docs/resources/domain) | resource |
| [libvirt_volume.cp](https://registry.terraform.io/providers/dmacvicar/libvirt/0.7.1/docs/resources/volume) | resource |
| [random_id.cluster_id](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/id) | resource |
| [random_id.cluster_secret](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/id) | resource |
| [random_id.secretbox_encryption_secret](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/id) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0-alpha.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0-alpha.0/docs/resources/machine_configuration_apply) | resource |
| [tls_cert_request.client_csr](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/cert_request) | resource |
| [tls_cert_request.k8s_client_csr](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/cert_request) | resource |
| [tls_locally_signed_cert.client_cert](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/locally_signed_cert) | resource |
| [tls_locally_signed_cert.k8s_client_cert](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/locally_signed_cert) | resource |
| [tls_private_key.client_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_private_key.etcd_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_private_key.k8s_aggregator_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_private_key.k8s_client_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_private_key.k8s_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_private_key.k8s_serviceaccount_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_private_key.os_key](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/private_key) | resource |
| [tls_self_signed_cert.etcd_cert](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.k8s_aggregator_cert](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.k8s_cert](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/self_signed_cert) | resource |
| [tls_self_signed_cert.os_cert](https://registry.terraform.io/providers/hashicorp/tls/4.0.4/docs/resources/self_signed_cert) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0-alpha.0/docs/data-sources/client_configuration) | data source |
| [talos_machine_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0-alpha.0/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | A name to provide for the Talos cluster | `string` | n/a | yes |
| <a name="input_iso_path"></a> [iso\_path](#input\_iso\_path) | Path to the Talos ISO | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | n/a |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | n/a |
<!-- END_TF_DOCS -->
