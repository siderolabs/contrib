# Talos specific variables
variable "image_id" {
  type = string
}

variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
  default     = "talos-hloud-cluster"
}

# Control plane
variable "controlplane_type" {
  default = "cpx31"
}

variable "controlplane_ip" {
  default = "10.0.0.3"
  type    = string
}

# Networking
variable "private_network_name" {
  default = "talos-network"
}

variable "private_network_ip_range" {
  default = "10.0.0.0/16"
}

variable "private_network_subnet_range" {
  default = "10.0.0.0/24"
}

# Load balancer
variable "network_zone" {
  default = "eu-central"
}

variable "load_balancer_type" {
  default = "lb11"
}

# Workers
variable "location" {
  default = "fsn1"
}

variable "workers" {
  description = "Worker definition"
}

variable "worker_extra_volume_size" {
  description = " Size of SSD volume to attach to workers"
  type        = number
  default     = 10
}
