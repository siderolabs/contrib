variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "talos-azure-example"
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

variable "azure_location" {
  description = "Azure location to use"
  type        = string
  default     = "West Europe"
}

variable "vm_size" {
  description = "VM size to use for the nodes"
  type        = string
  default     = "Standard_B2s"
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

variable "image_file" {
  description = "Path to the Talos image file to be used for the virtual machines"
  type        = string
  default     = "./disk.vhd"
}
