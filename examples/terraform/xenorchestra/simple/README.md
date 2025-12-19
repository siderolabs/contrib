<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_xenorchestra"></a> [xenorchestra](#provider\_xenorchestra) | 0.37.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [xenorchestra_vm.cp](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/resources/vm) | resource |
| [xenorchestra_vm.worker](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/resources/vm) | resource |
| [xenorchestra_network.net](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/data-sources/network) | data source |
| [xenorchestra_pool.pool](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/data-sources/pool) | data source |
| [xenorchestra_sr.shared_storage](https://registry.terraform.io/providers/vatesfr/xenorchestra/latest/docs/data-sources/sr) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the Talos cluster | `string` | `"demo-talos"` | no |
| <a name="input_cp_cpus"></a> [cp\_cpus](#input\_cp\_cpus) | Number of CPUs for control plane | `number` | `2` | no |
| <a name="input_cp_disk_size_gb"></a> [cp\_disk\_size\_gb](#input\_cp\_disk\_size\_gb) | Control plane disk size in GB | `number` | `20` | no |
| <a name="input_cp_memory_gb"></a> [cp\_memory\_gb](#input\_cp\_memory\_gb) | Memory size for control plane in GB | `number` | `4` | no |
| <a name="input_network_name"></a> [network\_name](#input\_network\_name) | Network name label | `string` | n/a | yes |
| <a name="input_pool_name"></a> [pool\_name](#input\_pool\_name) | Pool name label | `string` | n/a | yes |
| <a name="input_sr_name"></a> [sr\_name](#input\_sr\_name) | Shared storage name label | `string` | n/a | yes |
| <a name="input_tpl_talos_id"></a> [tpl\_talos\_id](#input\_tpl\_talos\_id) | Talos template ID | `string` | n/a | yes |
| <a name="input_worker_cpus"></a> [worker\_cpus](#input\_worker\_cpus) | Number of CPUs for worker | `number` | `2` | no |
| <a name="input_worker_disk_size_gb"></a> [worker\_disk\_size\_gb](#input\_worker\_disk\_size\_gb) | Worker disk size in GB | `number` | `20` | no |
| <a name="input_worker_memory_gb"></a> [worker\_memory\_gb](#input\_worker\_memory\_gb) | Memory size for worker in GB | `number` | `4` | no |
| <a name="input_xoa_token"></a> [xoa\_token](#input\_xoa\_token) | Xen Orchestra API token | `string` | n/a | yes |
| <a name="input_xoa_url"></a> [xoa\_url](#input\_xoa\_url) | Xen Orchestra server address | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->