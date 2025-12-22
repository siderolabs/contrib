<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.9.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.9.0 |
| <a name="provider_xenorchestra"></a> [xenorchestra](#provider\_xenorchestra) | 0.37.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/resources/machine_secrets) | resource |
| [xenorchestra_vm.cp](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/resources/vm) | resource |
| [xenorchestra_vm.worker](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/resources/vm) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/data-sources/client_configuration) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/data-sources/machine_configuration) | data source |
| [xenorchestra_network.net](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/data-sources/network) | data source |
| [xenorchestra_pool.pool](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/data-sources/pool) | data source |
| [xenorchestra_sr.shared_storage](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/data-sources/sr) | data source |
| [xenorchestra_vdi.iso](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/data-sources/vdi) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | The endpoint for the Talos cluster (defaults to https://<cluster\_vip>:6443) | `string` | `null` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the Talos cluster | `string` | `"demo-talos"` | no |
| <a name="input_cluster_vip"></a> [cluster\_vip](#input\_cluster\_vip) | The virtual IP for the Talos cluster | `string` | n/a | yes |
| <a name="input_cp_cpus"></a> [cp\_cpus](#input\_cp\_cpus) | Number of CPUs for control plane | `number` | `2` | no |
| <a name="input_cp_disk_size_gb"></a> [cp\_disk\_size\_gb](#input\_cp\_disk\_size\_gb) | Control plane disk size in GB | `number` | `20` | no |
| <a name="input_cp_memory_gb"></a> [cp\_memory\_gb](#input\_cp\_memory\_gb) | Memory size for control plane in GB | `number` | `4` | no |
| <a name="input_expected_ip_cidr"></a> [expected\_ip\_cidr](#input\_expected\_ip\_cidr) | Determines the IP CIDR range the provider will wait for on this network interface. | `string` | n/a | yes |
| <a name="input_iso_name"></a> [iso\_name](#input\_iso\_name) | ISO name label to mount on control plane nodes (optional). If provided, will also add /machine/install patches. | `string` | `null` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Network name label | `string` | n/a | yes |
| <a name="input_num_control_plane"></a> [num\_control\_plane](#input\_num\_control\_plane) | Number of control plane nodes to create | `number` | `3` | no |
| <a name="input_num_workers"></a> [num\_workers](#input\_num\_workers) | Number of worker nodes to create | `number` | `1` | no |
| <a name="input_pool_name"></a> [pool\_name](#input\_pool\_name) | Pool name label | `string` | n/a | yes |
| <a name="input_sr_name"></a> [sr\_name](#input\_sr\_name) | Shared storage name label | `string` | n/a | yes |
| <a name="input_tpl_talos_id"></a> [tpl\_talos\_id](#input\_tpl\_talos\_id) | Talos template ID | `string` | n/a | yes |
| <a name="input_worker_cpus"></a> [worker\_cpus](#input\_worker\_cpus) | Number of CPUs for worker | `number` | `2` | no |
| <a name="input_worker_disk_size_gb"></a> [worker\_disk\_size\_gb](#input\_worker\_disk\_size\_gb) | Worker disk size in GB | `number` | `20` | no |
| <a name="input_worker_memory_gb"></a> [worker\_memory\_gb](#input\_worker\_memory\_gb) | Memory size for worker in GB | `number` | `4` | no |
| <a name="input_xoa_token"></a> [xoa\_token](#input\_xoa\_token) | Xen Orchestra API token | `string` | n/a | yes |
| <a name="input_xoa_url"></a> [xoa\_url](#input\_xoa\_url) | Xen Orchestra server address | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | n/a |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | n/a |
<!-- END_TF_DOCS -->