<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_hcloud"></a> [hcloud](#requirement\_hcloud) | 1.48.1 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_hcloud"></a> [hcloud](#provider\_hcloud) | 1.48.1 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [hcloud_load_balancer.controlplane_load_balancer](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/load_balancer) | resource |
| [hcloud_load_balancer_network.srvnetwork](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/load_balancer_network) | resource |
| [hcloud_load_balancer_service.controlplane_load_balancer_service_kubectl](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/load_balancer_service) | resource |
| [hcloud_load_balancer_service.controlplane_load_balancer_service_mayastor](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/load_balancer_service) | resource |
| [hcloud_load_balancer_service.controlplane_load_balancer_service_talosctl](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/load_balancer_service) | resource |
| [hcloud_load_balancer_target.load_balancer_target](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/load_balancer_target) | resource |
| [hcloud_network.network](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/network) | resource |
| [hcloud_network_subnet.subnet](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/network_subnet) | resource |
| [hcloud_server.controlplane_server](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/server) | resource |
| [hcloud_server.worker_server](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/server) | resource |
| [hcloud_volume.volumes](https://registry.terraform.io/providers/hetznercloud/hcloud/1.48.1/docs/resources/volume) | resource |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.bootstrap](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/resources/machine_secrets) | resource |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/data-sources/client_configuration) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/0.7.0/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | A name to provide for the Talos cluster | `string` | `"talos-hloud-cluster"` | no |
| <a name="input_controlplane_ip"></a> [controlplane\_ip](#input\_controlplane\_ip) | n/a | `string` | `"10.0.0.3"` | no |
| <a name="input_controlplane_type"></a> [controlplane\_type](#input\_controlplane\_type) | Control plane | `string` | `"cx32"` | no |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | Talos specific variables | `string` | n/a | yes |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version to use for the cluster, if not set the k8s version shipped with the talos sdk version will be used | `string` | `null` | no |
| <a name="input_load_balancer_type"></a> [load\_balancer\_type](#input\_load\_balancer\_type) | n/a | `string` | `"lb11"` | no |
| <a name="input_location"></a> [location](#input\_location) | Workers | `string` | `"fsn1"` | no |
| <a name="input_network_zone"></a> [network\_zone](#input\_network\_zone) | Load balancer | `string` | `"eu-central"` | no |
| <a name="input_private_network_ip_range"></a> [private\_network\_ip\_range](#input\_private\_network\_ip\_range) | n/a | `string` | `"10.0.0.0/16"` | no |
| <a name="input_private_network_name"></a> [private\_network\_name](#input\_private\_network\_name) | Networking | `string` | `"talos-network"` | no |
| <a name="input_private_network_subnet_range"></a> [private\_network\_subnet\_range](#input\_private\_network\_subnet\_range) | n/a | `string` | `"10.0.0.0/24"` | no |
| <a name="input_talos_version_contract"></a> [talos\_version\_contract](#input\_talos\_version\_contract) | Talos API version to use for the cluster, if not set the the version shipped with the talos sdk version will be used | `string` | `"v1.6"` | no |
| <a name="input_worker_extra_volume_size"></a> [worker\_extra\_volume\_size](#input\_worker\_extra\_volume\_size) | Size of SSD volume to attach to workers | `number` | `10` | no |
| <a name="input_workers"></a> [workers](#input\_workers) | Worker definition | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | n/a |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | n/a |
<!-- END_TF_DOCS -->