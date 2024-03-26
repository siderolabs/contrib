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
    ipxe_script_url    = optional(string, "https://pxe.factory.talos.dev/pxe/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.7.0/equinixMetal-amd64")
    install_image      = optional(string, "ghcr.io/talos-systems/installer:v1.7.0")
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
    ipxe_script_url    = optional(string, "https://pxe.factory.talos.dev/pxe/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/v1.7.0/equinixMetal-amd64")
    install_image      = optional(string, "ghcr.io/talos-systems/installer:v1.7.0")
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
