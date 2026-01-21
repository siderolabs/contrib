variable "pve_node" {
  description = "The name of the PVE node to put Talos nodes on"
  type        = string
}

variable "control_plane_nodes_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 3
}

variable "total_control_plane_memory" {
  description = "Total memory to be split up amongst control plane nodes"
  type        = number
  default     = 12 * 1024
}

variable "control_plane_cores" {
  description = "How many cores to be given to each control plane node"
  type        = number
  default     = 2 
}

variable "control_plane_sockets" {
  description = "How many sockets to be given to each control plane node"
  type        = number
  default     = 2 
}

variable "total_work_plane_memory" {
  description = "Total memory to be split up amongst control plane nodes"
  type        = number
  default     = 12 * 1024
}

variable "worker_nodes_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "worker_cores" {
  description = "How many cores to be given to each work plane node"
  type        = number
  default     = 2 
}

variable "worker_sockets" {
  description = "How many sockets to be given to each work plane node"
  type        = number
  default     = 2 
}

variable "pve_talos_template_name" {
  description = "The name of the template to clone"
  type        = string
}

variable "pve_bridge" {
  description = "The Linux virtual bridge on which nodes' NICs will be assigned"
  type        = string
  default     = "vmbr0"
}

variable "pve_vlan_tag" {
  description = "The VLAN tag to assign to the nodes' NICs"
  type        = number 
  default     = -1 
}

variable "pve_tags" {
  description = "Any tags to add to the nodes"
  type        = string
  default     = ""
}

variable "pve_boot_disk_storage" {
  description = "Where to store nodes' boot disks"
  type        = string
}

variable "pve_boot_disk_size" {
  description = "Storage size of nodes' boot disks"
  type        = string
  default     = "12G"
}

variable "pve_talos_iso" {
  description = "The ISO PVE should boot nodes from (this must be downloaded to PVE already)"
  type        = string
}

variable "pve_passthrough_disks" {
  description = "A list of physical disks to pass through to worker nodes"
  type        = set(string)
  default     = []
}

variable "pve_vmid_start" {
  description = "The ID for VMs to start from"
  type        = number
  default     = 100
}

variable "pve_agent_timeout" {
  description = "How many seconds to wait for VMs' guest agents"
  type        = number
  default     = 60
}

variable "talos_cluster_name" {
  description = "The name of your Talos cluster"
  type        = string
  default     = "pve-talos"
}

variable "talos_install_image" {
  description = "The Talos image to install from (get this from factory.talos.dev)"
  type        = string
}
