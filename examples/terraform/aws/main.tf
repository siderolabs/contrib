locals {
  common_machine_config_patch = {
    machine = {
      kubelet = {
        registerWithFQDN = true
      }
    }
  }

  ccm_patch_cp = {
    cluster = {
      externalCloudProvider = {
        enabled = true
        manifests = [
          "https://raw.githubusercontent.com/siderolabs/contrib/main/examples/terraform/aws/manifests/ccm.yaml"
        ]
      }
    }
  }

  ccm_patch_worker = {
    cluster = {
      externalCloudProvider = {
        enabled = true
      }
    }
  }

  config_patches_common = [
    for path in var.config_patch_files : file(path)
  ]

  config_patches_controlplane = var.ccm ? [yamlencode(local.ccm_patch_cp)] : []

  config_patches_worker = var.ccm ? [yamlencode(local.ccm_patch_worker)] : []

  cluster_required_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "talos" {
  owners      = ["540036508848"] # Sidero Labs
  most_recent = true
  name_regex  = "^talos-v\\d+\\.\\d+\\.\\d+-${data.aws_availability_zones.available.id}-amd64$"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = var.cluster_name
  cidr = var.vpc_cidr
  tags = var.extra_tags

  # lets pick utmost three AZ's since the CIDR bit is 2
  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets = [for i, v in slice(data.aws_availability_zones.available.names, 0, 3) : cidrsubnet(var.vpc_cidr, 2, i)]
}

module "cluster_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = var.cluster_name
  description = "Allow all intra-cluster and egress traffic"
  vpc_id      = module.vpc.vpc_id
  tags        = var.extra_tags

  ingress_with_self = [
    {
      rule = "all-all"
    },
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 50000
      to_port     = 50000
      protocol    = "tcp"
      cidr_blocks = var.talos_api_allowed_cidr
      description = "Talos API Access"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "kubernetes_api_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "~> 4.0"

  name                = "${var.cluster_name}-k8s-api"
  description         = "Allow access to the Kubernetes API"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = [var.kubernetes_api_allowed_cidr]
  tags                = var.extra_tags
}

module "elb_k8s_elb" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 4.0"

  name    = substr("${var.cluster_name}-k8s-api", 0, 32)
  subnets = module.vpc.public_subnets
  tags    = merge(var.extra_tags, local.cluster_required_tags)
  security_groups = [
    module.cluster_sg.security_group_id,
    module.kubernetes_api_sg.security_group_id,
  ]

  listener = [
    {
      lb_port           = 443
      lb_protocol       = "tcp"
      instance_port     = 6443
      instance_protocol = "tcp"
    },
  ]

  health_check = {
    target              = "tcp:6443"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  number_of_instances = var.control_plane.num_instances
  instances           = module.talos_control_plane_nodes.*.id
}

# https://cloud-provider-aws.sigs.k8s.io/prerequisites/
resource "aws_iam_policy" "control_plane_ccm_policy" {
  count = var.ccm ? 1 : 0

  name        = "${var.cluster_name}-control-plane-ccm-policy"
  path        = "/"
  description = "IAM policy for the control plane nodes to allow CCM to manage AWS resources"

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:DescribeTags",
            "ec2:DescribeInstances",
            "ec2:DescribeRegions",
            "ec2:DescribeRouteTables",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeVolumes",
            "ec2:DescribeAvailabilityZones",
            "ec2:CreateSecurityGroup",
            "ec2:CreateTags",
            "ec2:CreateVolume",
            "ec2:ModifyInstanceAttribute",
            "ec2:ModifyVolume",
            "ec2:AttachVolume",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:CreateRoute",
            "ec2:DeleteRoute",
            "ec2:DeleteSecurityGroup",
            "ec2:DeleteVolume",
            "ec2:DetachVolume",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:DescribeVpcs",
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:AttachLoadBalancerToSubnets",
            "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateLoadBalancerPolicy",
            "elasticloadbalancing:CreateLoadBalancerListeners",
            "elasticloadbalancing:ConfigureHealthCheck",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:DeleteLoadBalancerListeners",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DetachLoadBalancerFromSubnets",
            "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
            "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:CreateTargetGroup",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:DeleteTargetGroup",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeLoadBalancerPolicies",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
            "iam:CreateServiceLinkedRole",
            "kms:DescribeKey"
          ],
          Resource = [
            "*"
          ]
        }
      ]
    }
  )
}

# https://cloud-provider-aws.sigs.k8s.io/prerequisites/
resource "aws_iam_policy" "worker_ccm_policy" {
  count = var.ccm ? 1 : 0

  name        = "${var.cluster_name}-worker-ccm-policy"
  path        = "/"
  description = "IAM policy for the worker nodes to allow CCM to manage AWS resources"

  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Effect : "Allow",
          Action : [
            "ec2:DescribeInstances",
            "ec2:DescribeRegions",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:BatchGetImage"
          ],
          Resource = "*"
        }
      ]
  })
}

module "talos_control_plane_nodes" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  count = var.control_plane.num_instances

  name                        = "${var.cluster_name}-control-plane-${count.index}"
  ami                         = var.control_plane.ami_id == null ? data.aws_ami.talos.id : var.control_plane.ami_id
  monitoring                  = true
  instance_type               = var.control_plane.instance_type
  subnet_id                   = element(module.vpc.public_subnets, count.index)
  iam_role_use_name_prefix    = false
  create_iam_instance_profile = var.ccm ? true : false
  iam_role_policies = var.ccm ? {
    "${var.cluster_name}-control-plane-ccm-policy" : aws_iam_policy.control_plane_ccm_policy[0].arn,
  } : {}
  tags = merge(var.extra_tags, var.control_plane.tags, local.cluster_required_tags)

  vpc_security_group_ids = [module.cluster_sg.security_group_id]

  root_block_device = [
    {
      volume_size = 100
    }
  ]
}

module "talos_worker_group" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  for_each = merge([for info in var.worker_groups : { for index in range(0, info.num_instances) : "${info.name}.${index}" => info }]...)

  name                        = "${var.cluster_name}-worker-group-${each.value.name}-${trimprefix(each.key, "${each.value.name}.")}"
  ami                         = each.value.ami_id == null ? data.aws_ami.talos.id : each.value.ami_id
  monitoring                  = true
  instance_type               = each.value.instance_type
  subnet_id                   = element(module.vpc.public_subnets, tonumber(trimprefix(each.key, "${each.value.name}.")))
  iam_role_use_name_prefix    = false
  create_iam_instance_profile = var.ccm ? true : false
  iam_role_policies = var.ccm ? {
    "${var.cluster_name}-worker-ccm-policy" : aws_iam_policy.worker_ccm_policy[0].arn,
  } : {}
  tags = merge(each.value.tags, var.extra_tags, local.cluster_required_tags)

  vpc_security_group_ids = [module.cluster_sg.security_group_id]

  root_block_device = [
    {
      volume_size = 100
    }
  ]
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${module.elb_k8s_elb.elb_dns_name}"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches = concat(
    local.config_patches_common,
    local.config_patches_controlplane,
    [yamlencode(local.common_machine_config_patch)],
    [for path in var.control_plane.config_patch_files : file(path)]
  )
}

data "talos_machine_configuration" "worker_group" {
  for_each = merge([for info in var.worker_groups : { "${info.name}" = info }]...)

  cluster_name       = var.cluster_name
  cluster_endpoint   = "https://${module.elb_k8s_elb.elb_dns_name}"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version_contract
  kubernetes_version = var.kubernetes_version
  docs               = false
  examples           = false
  config_patches = concat(
    local.config_patches_common,
    local.config_patches_worker,
    [yamlencode(local.common_machine_config_patch)],
    [for path in each.value.config_patch_files : file(path)]
  )
}

resource "talos_machine_configuration_apply" "controlplane" {
  count = var.control_plane.num_instances

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  endpoint                    = module.talos_control_plane_nodes[count.index].public_ip
  node                        = module.talos_control_plane_nodes[count.index].private_ip
}

resource "talos_machine_configuration_apply" "worker_group" {
  for_each = merge([
    for info in var.worker_groups : {
      for index in range(0, info.num_instances) :
      "${info.name}.${index}" => {
        name       = info.name,
        public_ip  = module.talos_worker_group["${info.name}.${index}"].public_ip,
        private_ip = module.talos_worker_group["${info.name}.${index}"].private_ip
      }
    }
  ]...)

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker_group[each.value.name].machine_configuration
  endpoint                    = module.talos_worker_group[each.key].public_ip
  node                        = module.talos_worker_group[each.key].private_ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = module.talos_control_plane_nodes.0.public_ip
  node                 = module.talos_control_plane_nodes.0.private_ip
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = module.talos_control_plane_nodes.*.public_ip
  nodes                = flatten([module.talos_control_plane_nodes.*.public_ip, flatten([for node in module.talos_worker_group : node.private_ip])])
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = module.talos_control_plane_nodes.0.public_ip
  node                 = module.talos_control_plane_nodes.0.private_ip
}

data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker_group,
    talos_cluster_kubeconfig.this
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = module.talos_control_plane_nodes.*.public_ip
  control_plane_nodes  = module.talos_control_plane_nodes.*.private_ip
  worker_nodes         = [for node in module.talos_worker_group : node.private_ip]
}
