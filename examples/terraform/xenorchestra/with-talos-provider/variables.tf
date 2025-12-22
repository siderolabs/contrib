variable "xoa_token" {
  description = "Xen Orchestra API token"
  type        = string
  sensitive   = true
}

variable "xoa_url" {
  description = "Xen Orchestra server address"
  type        = string
}

variable "tpl_talos_id" {
  description = "Talos template ID"
  type        = string
}

variable "iso_name" {
  description = "ISO name label to mount on control plane nodes (optional). If provided, will also add /machine/install patches."
  type        = string
  default     = null
}

variable "pool_name" {
  description = "Pool name label"
  type        = string
}

variable "sr_name" {
  description = "Shared storage name label"
  type        = string
}

variable "network_name" {
  description = "Network name label"
  type        = string
}

variable "expected_ip_cidr" {
  description = "Determines the IP CIDR range the provider will wait for on this network interface."
  type        = string
}

variable "cluster_name" {
  description = "Name of the Talos cluster"
  type        = string
  default     = "demo-talos"
}

variable "cluster_vip" {
  description = "The virtual IP for the Talos cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint for the Talos cluster (defaults to https://<cluster_vip>:6443)"
  type        = string
  default     = null
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

variable "cp_cpus" {
  description = "Number of CPUs for control plane"
  type        = number
  default     = 2
}

variable "cp_memory_gb" {
  description = "Memory size for control plane in GB"
  type        = number
  default     = 4
}

variable "cp_disk_size_gb" {
  description = "Control plane disk size in GB"
  type        = number
  default     = 20
}

variable "worker_cpus" {
  description = "Number of CPUs for worker"
  type        = number
  default     = 2
}

variable "worker_memory_gb" {
  description = "Memory size for worker in GB"
  type        = number
  default     = 4
}

variable "worker_disk_size_gb" {
  description = "Worker disk size in GB"
  type        = number
  default     = 20
}
