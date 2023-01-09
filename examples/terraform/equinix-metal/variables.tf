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

variable "em_region" {
  description = "Equinix Metal region to use"
  type        = string
  default     = "dc"
}

variable "em_plan" {
  description = "Equinix Metal server to use"
  type        = string
  default     = "c3.small.x86"
}

variable "em_project_id" {
  description = "Equinix Metal project ID"
  type        = string
}
