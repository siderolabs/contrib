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

  azs             = data.aws_availability_zones.available.names
  public_subnets  = [for i, v in data.aws_availability_zones.available.names: cidrsubnet(var.vpc_cidr, 2, i)]
}

module "cluster_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "${var.cluster_name}"
  description = "Allow all intra-cluster and egress traffic"
  vpc_id      = module.vpc.vpc_id

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
}

module "elb_k8s_elb" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 4.0"

  name            = "${var.cluster_name}-k8s-api"
  subnets         = module.vpc.public_subnets
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

  number_of_instances = var.num_control_planes
  instances           = module.talos_control_plane_nodes.*.id
}

module "talos_control_plane_nodes" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  count = var.num_control_planes

  name          = "${var.cluster_name}-control-plane-${count.index}"
  ami           = data.aws_ami.talos.id
  monitoring    = true
  instance_type = var.instance_type
  subnet_id     = element(module.vpc.public_subnets, count.index)

  vpc_security_group_ids = [module.cluster_sg.security_group_id]

  root_block_device = [
    {
      volume_size = 100
    }
  ]
}

module "talos_worker_nodes" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.0"

  count = var.num_workers

  name          = "${var.cluster_name}-worker-${count.index}"
  ami           = data.aws_ami.talos.id
  monitoring    = true
  instance_type = var.instance_type
  subnet_id     = element(module.vpc.public_subnets, count.index)

  vpc_security_group_ids = [module.cluster_sg.security_group_id]

  root_block_device = [
    {
      volume_size = 100
    }
  ]
}

resource "talos_machine_secrets" "this" {}

resource "talos_machine_configuration_controlplane" "this" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${module.elb_k8s_elb.elb_dns_name}"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  docs_enabled     = false
  examples_enabled = false
}

resource "talos_machine_configuration_worker" "this" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${module.elb_k8s_elb.elb_dns_name}"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  docs_enabled     = false
  examples_enabled = false
}

resource "talos_machine_configuration_apply" "controlplane" {
  count = var.num_control_planes

  talos_config          = talos_client_configuration.this.talos_config
  machine_configuration = talos_machine_configuration_controlplane.this.machine_config
  endpoint              = module.talos_control_plane_nodes[count.index].public_ip
  node                  = module.talos_control_plane_nodes[count.index].private_ip
}

resource "talos_machine_configuration_apply" "worker" {
  count = var.num_workers

  talos_config          = talos_client_configuration.this.talos_config
  machine_configuration = talos_machine_configuration_worker.this.machine_config
  endpoint              = module.talos_worker_nodes[count.index].public_ip
  node                  = module.talos_worker_nodes[count.index].private_ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  talos_config = talos_client_configuration.this.talos_config
  endpoint     = module.talos_control_plane_nodes.0.public_ip
  node         = module.talos_control_plane_nodes.0.private_ip
}

resource "talos_client_configuration" "this" {
  cluster_name    = var.cluster_name
  machine_secrets = talos_machine_secrets.this.machine_secrets
  endpoints       = module.talos_control_plane_nodes.*.public_ip
  nodes           = flatten([module.talos_control_plane_nodes.*.private_ip, module.talos_worker_nodes.*.private_ip])
}

resource "talos_cluster_kubeconfig" "this" {
  talos_config = talos_client_configuration.this.talos_config
  endpoint     = module.talos_control_plane_nodes.0.public_ip
  node         = module.talos_control_plane_nodes.0.private_ip
}
