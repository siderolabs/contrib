variable "cluster_name" {
  description = "Name of cluster"
  type        = string
  default     = "talos-vultr"
}

variable "num_control_plane" {
  description = "Number of control plane nodes to create"
  type        = number
  default     = 3
}

variable "num_workers" {
  description = "Number of worker nodes to create"
  type        = number
  default     = 1
}

variable "vultr_region" {
  description = "Vultr region to use"
  type        = string
  default     = "atl"
}

variable "vultr_plan" {
  description = "Vultr plan to use"
  type        = string
  default     = "vc2-2c-4gb"
}
