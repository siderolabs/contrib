variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "talos-aws-example"
}

variable "num_control_planes" {
  description = "Number of control plane nodes to create"
  type        = number
  default     = 3
}

variable "num_workers" {
  description = "Number of worker nodes to create"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "Instance type to use for the control plane nodes"
  type        = string
  default     = "c5.large"
}

variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "172.16.0.0/16"
}

variable "talos_api_allowed_cidr" {
  description = "The CIDR from which to allow to access the Talos API"
  type        = string
  default     = "0.0.0.0/0"
}

variable "kubernetes_api_allowed_cidr" {
  description = "The CIDR from which to allow to access the Kubernetes API"
  type        = string
  default     = "0.0.0.0/0"
}
