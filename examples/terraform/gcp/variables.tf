variable "project" {
  description = "The GCP project to deploy resources to"
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources to"
  type        = string
}

variable "zone" {
  description = "The GCP zone to deploy resources to"
  type        = string
}

variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "talos-gcp-example"
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
    instance_type      = optional(string, "e2-standard-2")
    image              = optional(string, null)
    num_instances      = optional(number, 3)
    config_patch_files = optional(list(string), [])
    tags               = optional(map(string), {})
  })

  default = {}
}

variable "worker_groups" {
  description = "List of node worker node groups to create"
  type = list(object({
    name               = string
    instance_type      = optional(string, "e2-standard-2")
    image              = optional(string, null)
    num_instances      = optional(number, 1)
    config_patch_files = optional(list(string), [])
    tags               = optional(map(string), {})
  }))


  default = [{
    name = "default"
  }]
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

variable "config_patch_files" {
  description = "Path to talos config path files that applies to all nodes"
  type        = list(string)
  default     = []
}
