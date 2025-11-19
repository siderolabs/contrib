<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 6.0 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.9.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 6.35.0 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.9.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-google-modules/network/google | ~> 9.1 |

## Resources

| Name | Type |
|------|------|
| [google_compute_backend_service.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | resource |
| [google_compute_firewall.health-check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.talos-api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_global_address.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_global_forwarding_rule.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) | resource |
| [google_compute_health_check.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_instance.cp](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_instance.workers](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance) | resource |
| [google_compute_instance_group.talos-cp-ig](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group) | resource |
| [google_compute_instance_group_membership.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_group_membership) | resource |
| [google_compute_target_tcp_proxy.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_tcp_proxy) | resource |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker_group](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/resources/machine_secrets) | resource |
| [google_compute_zones.available](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_zones) | data source |
| [google_netblock_ip_ranges.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/netblock_ip_ranges) | data source |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/data-sources/client_configuration) | data source |
| [talos_cluster_health.this](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/data-sources/cluster_health) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker_group](https://registry.terraform.io/providers/siderolabs/talos/0.9.0/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of cluster | `string` | `"talos-gcp-example"` | no |
| <a name="input_config_patch_files"></a> [config\_patch\_files](#input\_config\_patch\_files) | Path to talos config path files that applies to all nodes | `list(string)` | `[]` | no |
| <a name="input_control_plane"></a> [control\_plane](#input\_control\_plane) | Info for control plane that will be created | <pre>object({<br/>    instance_type      = optional(string, "e2-standard-2")<br/>    image              = optional(string, null)<br/>    num_instances      = optional(number, 3)<br/>    config_patch_files = optional(list(string), [])<br/>    tags               = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version to use for the cluster, if not set the k8s version shipped with the talos sdk version will be used | `string` | `null` | no |
| <a name="input_project"></a> [project](#input\_project) | The GCP project to deploy resources to | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The GCP region to deploy resources to | `string` | n/a | yes |
| <a name="input_talos_api_allowed_cidr"></a> [talos\_api\_allowed\_cidr](#input\_talos\_api\_allowed\_cidr) | The CIDR from which to allow to access the Talos API | `string` | `"0.0.0.0/0"` | no |
| <a name="input_talos_version_contract"></a> [talos\_version\_contract](#input\_talos\_version\_contract) | Talos API version to use for the cluster, if not set the the version shipped with the talos sdk version will be used | `string` | `null` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The IPv4 CIDR block for the VPC. | `string` | `"172.16.0.0/16"` | no |
| <a name="input_worker_groups"></a> [worker\_groups](#input\_worker\_groups) | List of node worker node groups to create | <pre>list(object({<br/>    name               = string<br/>    instance_type      = optional(string, "e2-standard-2")<br/>    image              = optional(string, null)<br/>    num_instances      = optional(number, 1)<br/>    config_patch_files = optional(list(string), [])<br/>    tags               = optional(map(string), {})<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "default"<br/>  }<br/>]</pre> | no |
| <a name="input_zone"></a> [zone](#input\_zone) | The GCP zone to deploy resources to | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | The generated kubeconfig. |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | The generated talosconfig. |
<!-- END_TF_DOCS -->