<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.21.0 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | 0.10.0-beta.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.21.0 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.10.0-beta.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_sg"></a> [cluster\_sg](#module\_cluster\_sg) | terraform-aws-modules/security-group/aws | ~> 5.0 |
| <a name="module_elb_k8s_elb"></a> [elb\_k8s\_elb](#module\_elb\_k8s\_elb) | terraform-aws-modules/elb/aws | ~> 4.0 |
| <a name="module_kubernetes_api_sg"></a> [kubernetes\_api\_sg](#module\_kubernetes\_api\_sg) | terraform-aws-modules/security-group/aws//modules/https-443 | ~> 5.0 |
| <a name="module_talos_control_plane_nodes"></a> [talos\_control\_plane\_nodes](#module\_talos\_control\_plane\_nodes) | terraform-aws-modules/ec2-instance/aws | ~> 6.0 |
| <a name="module_talos_worker_group"></a> [talos\_worker\_group](#module\_talos\_worker\_group) | terraform-aws-modules/ec2-instance/aws | ~> 6.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 6.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.control_plane_ccm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.worker_ccm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/0.10.0-beta.0/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/0.10.0-beta.0/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.10.0-beta.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker_group](https://registry.terraform.io/providers/siderolabs/talos/0.10.0-beta.0/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/0.10.0-beta.0/docs/resources/machine_secrets) | resource |
| [aws_ami.talos](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/0.10.0-beta.0/docs/data-sources/client_configuration) | data source |
| [talos_cluster_health.this](https://registry.terraform.io/providers/siderolabs/talos/0.10.0-beta.0/docs/data-sources/cluster_health) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/0.10.0-beta.0/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker_group](https://registry.terraform.io/providers/siderolabs/talos/0.10.0-beta.0/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ccm"></a> [ccm](#input\_ccm) | Whether to deploy aws cloud controller manager | `bool` | `false` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of cluster | `string` | `"talos-aws-example"` | no |
| <a name="input_config_patch_files"></a> [config\_patch\_files](#input\_config\_patch\_files) | Path to talos config path files that applies to all nodes | `list(string)` | `[]` | no |
| <a name="input_control_plane"></a> [control\_plane](#input\_control\_plane) | Info for control plane that will be created | <pre>object({<br/>    instance_type      = optional(string, "c5.large")<br/>    ami_id             = optional(string, null)<br/>    num_instances      = optional(number, 3)<br/>    config_patch_files = optional(list(string), [])<br/>    tags               = optional(map(string), {})<br/>  })</pre> | `{}` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to add to the cluster cloud resources | `map(string)` | `{}` | no |
| <a name="input_kubernetes_api_allowed_cidr"></a> [kubernetes\_api\_allowed\_cidr](#input\_kubernetes\_api\_allowed\_cidr) | The CIDR from which to allow to access the Kubernetes API | `string` | `"0.0.0.0/0"` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version to use for the cluster, if not set the k8s version shipped with the talos sdk version will be used | `string` | `null` | no |
| <a name="input_talos_api_allowed_cidr"></a> [talos\_api\_allowed\_cidr](#input\_talos\_api\_allowed\_cidr) | The CIDR from which to allow to access the Talos API | `string` | `"0.0.0.0/0"` | no |
| <a name="input_talos_version_contract"></a> [talos\_version\_contract](#input\_talos\_version\_contract) | Talos API version to use for the cluster, if not set the the version shipped with the talos sdk version will be used | `string` | `null` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The IPv4 CIDR block for the VPC. | `string` | `"172.16.0.0/16"` | no |
| <a name="input_worker_groups"></a> [worker\_groups](#input\_worker\_groups) | List of node worker node groups to create | <pre>list(object({<br/>    name               = string<br/>    instance_type      = optional(string, "c5.large")<br/>    ami_id             = optional(string, null)<br/>    num_instances      = optional(number, 1)<br/>    config_patch_files = optional(list(string), [])<br/>    tags               = optional(map(string), {})<br/>  }))</pre> | <pre>[<br/>  {<br/>    "name": "default"<br/>  }<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | The generated kubeconfig. |
| <a name="output_talosconfig"></a> [talosconfig](#output\_talosconfig) | The generated talosconfig. |
<!-- END_TF_DOCS -->
