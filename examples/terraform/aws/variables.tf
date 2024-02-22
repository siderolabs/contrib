variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "talos-aws-example"
}

variable "ccm" {
  description = "Whether to deploy aws cloud controller manager"
  type        = bool
  default     = false
}

variable "talos_version_contract" {
  description = "Talos API version to use for the cluster, if not set the the version shipped with the talos sdk version will be used"
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster, if not set the k8s version shipped with the talos sdk version will be used"
  type        = string
  default     = null
}

variable "control_plane" {
  description = "Info for control plane that will be created"
  type = object({
    instance_type      = optional(string, "c5.large")
    ami_id             = optional(string, null)
    num_instances      = optional(number, 3)
    config_patch_files = optional(list(string), [])
    tags               = optional(map(string), {})
  })

  validation {
    condition     = var.control_plane.ami_id != null ? (length(var.control_plane.ami_id) > 4 && substr(var.control_plane.ami_id, 0, 4) == "ami-") : true
    error_message = "The ami_id value must be a valid AMI id, starting with \"ami-\"."
  }

  default = {}
}

variable "worker_groups" {
  description = "List of node worker node groups to create"
  type = list(object({
    name               = string
    instance_type      = optional(string, "c5.large")
    ami_id             = optional(string, null)
    num_instances      = optional(number, 1)
    config_patch_files = optional(list(string), [])
    tags               = optional(map(string), {})
  }))

  validation {
    condition = (
      alltrue([
        for wg in var.worker_groups : (
          wg.ami_id != null ? (length(wg.ami_id) > 4 && substr(wg.ami_id, 0, 4) == "ami-") : true
        )
      ])
    )
    error_message = "The ami_id value must be a valid AMI id, starting with \"ami-\"."
  }
  default = [{
    name = "default"
  }]
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
