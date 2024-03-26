variable "em_api_token" {
  description = "API token for Equinix Metal"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "talos-em"
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
    plan               = optional(string, "c3.small.x86")
    ipxe_script_url    = optional(string, "https://pxe.factory.talos.dev/pxe/a6ef1cf923b0b123f88968fb611f4b4d5e53dd8f77be11ba010a38c4bab7f505/v1.7.0-alpha.1/metal-amd64")
    num_instances      = optional(number, 3)
    config_patch_files = optional(list(string), [])
    tags               = optional(list(string), [])
  })

  default = {}
}

variable "worker_groups" {
  description = "List of node worker node groups to create"
  type = list(object({
    name               = string
    plan               = optional(string, "c3.small.x86")
    ipxe_script_url    = optional(string, "https://pxe.factory.talos.dev/pxe/a6ef1cf923b0b123f88968fb611f4b4d5e53dd8f77be11ba010a38c4bab7f505/v1.7.0-alpha.1/metal-amd64")
    num_instances      = optional(number, 1)
    config_patch_files = optional(list(string), [])
    tags               = optional(list(string), [])
  }))

  default = [{
    name = "default"
  }]
}

variable "extra_tags" {
  description = "Extra tags to add to the cluster cloud resources"
  type        = list(string)
  default     = []
}

variable "config_patch_files" {
  description = "Path to talos config path files that applies to all nodes"
  type        = list(string)
  default     = []
}

variable "em_region" {
  description = "Equinix Metal region to use"
  type        = string
  default     = "dc"
}

variable "em_project_id" {
  description = "Equinix Metal project ID"
  type        = string
}
