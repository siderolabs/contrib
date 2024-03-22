variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "talos-azure-example"
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
    vm_size            = optional(string, "Standard_B2s")
    vm_os_id           = optional(string, "/subscriptions/7f739b7d-f399-4b97-9a9f-f1962309ee6e/resourceGroups/SideroGallery/providers/Microsoft.Compute/galleries/SideroLabs/images/talos-x64/versions/latest")
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
    vm_size            = optional(string, "Standard_B2s")
    vm_os_id           = optional(string, "/subscriptions/7f739b7d-f399-4b97-9a9f-f1962309ee6e/resourceGroups/SideroGallery/providers/Microsoft.Compute/galleries/SideroLabs/images/talos-x64/versions/latest")
    num_instances      = optional(number, 1)
    config_patch_files = optional(list(string), [])
    tags               = optional(map(string), {})
  }))

  default = [{
    name = "default"
  }]
}

variable "extra_tags" {
  description = "Extra tags to add to the cluster cloud resources"
  type        = map(string)
  default     = {}
}

variable "config_patch_files" {
  description = "Path to talos config path files that applies to all nodes"
  type        = list(string)
  default     = []
}

variable "azure_location" {
  description = "Azure location to use"
  type        = string
  default     = "West Europe"
}

variable "vnet_cidr" {
  description = "The IPv4 CIDR block for the Virtual Network."
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
