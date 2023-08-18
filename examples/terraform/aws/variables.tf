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

variable "ami_id" {
  description = "AMI ID to use for talos nodes, if not set the latest talos release ami id will be looked up"
  type        = string
  default     = ""
  validation {
    condition     = length(var.ami_id) > 0 ? (length(var.ami_id) > 4 && substr(var.ami_id, 0, 4) == "ami-") : true
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
  }
}

variable "instance_type_control_plane" {
  description = "Instance type to use for the control plane nodes"
  type        = string
  default     = "c5.large"
}

variable "instance_type_worker" {
  description = "Instance type to use for the worker nodes"
  type        = string
  default     = "c5.large"
}

variable "ccm" {
  description = "Whether to deploy aws cloud controller manager"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster, if not set the k8s version shipped with the talos sdk version will be used"
  type        = string
  default     = null
}

variable "worker_groups" {
  description = "List of node worker node groups to create"
  type = list(object({
    name               = string
    instance_type      = string
    ami_id             = optional(string, null)
    num_instances      = optional(number, 1)
    kubernetes_version = optional(string, null)
    config_patch_files = optional(list(string), [])
    tags               = optional(map(string), {})
  }))
  default = []
}

variable "extra_tags" {
  description = "Extra tags to add to the cluster cloud resources"
  type        = map(string)
  default     = {}
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

variable "config_patch_files" {
  description = "Path to talos config path files that applies to all nodes"
  type        = list(string)
  default     = []
}

variable "config_patch_files_control_plane" {
  description = "Path to talos config path files that applies to all control plane nodes"
  type        = list(string)
  default     = []
}

variable "config_patch_files_worker" {
  description = "Path to talos config path files that applies to all worker nodes"
  type        = list(string)
  default     = []
}
