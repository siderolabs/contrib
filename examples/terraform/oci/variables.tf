variable "compartment_ocid" {
  type      = string
  sensitive = true
}
variable "tenancy_ocid" {
  type      = string
  sensitive = true
}
variable "user_ocid" {
  type      = string
  sensitive = true
}
variable "fingerprint" {
  type      = string
  sensitive = true
}
variable "private_key_path" {
  type      = string
  default   = "~/.oci/oci_main_terraform.pem"
  sensitive = true
}
variable "instance_availability_domain" {
  type    = string
  default = null
}
variable "region" {
  description = "the OCI region where resources will be created"
  type        = string
  default     = null
}
variable "cluster_name" {
  type    = string
  default = "talosoci"
}
variable "kube_apiserver_domain" {
  type    = string
  default = null
}
variable "cidr_blocks" {
  type    = set(string)
  default = ["10.0.0.0/16"]
}
variable "subnet_block" {
  type    = string
  default = "10.0.0.0/24"
}
variable "subnet_block_regional" {
  type    = string
  default = "10.0.10.0/24"
}
variable "talos_version" {
  type    = string
  default = "v1.7.6"
}
variable "kubernetes_version" {
  type    = string
  default = "v1.30.3"
}
variable "instance_shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}
variable "oracle_cloud_ccm_version" {
  type    = string
  default = "v1.29.0"
}
variable "talos_ccm_version" {
  type    = string
  default = "v1.6.0"
}
variable "pod_subnet_block" {
  type    = string
  default = "10.32.0.0/12"
}
variable "service_subnet_block" {
  type    = string
  default = "10.200.0.0/22"
}
variable "architecture" {
  type    = string
  default = "arm64"
}
variable "talos_extensions" {
  type = set(string)
  default = [
    "gvisor",
    "kata-containers",
    "iscsi-tools",
    "mdadm",
  ]
}
variable "controlplane_instance_count" {
  type    = number
  default = 3
}
variable "worker_instance_count" {
  type    = number
  default = 6
}
variable "talos_image_oci_bucket_url" {
  type     = string
  nullable = false
}
variable "controlplane_instance_ocpus" {
  type    = number
  default = 4
}
variable "controlplane_instance_memory_in_gbs" {
  type    = string
  default = "8"
}
variable "worker_instance_ocpus" {
  type    = number
  default = 4
}
variable "worker_instance_memory_in_gbs" {
  type    = string
  default = "8"
}
variable "worker_volume_enabled" {
  type    = bool
  default = true
}
variable "worker_volume_size_in_gbs" {
  type    = string
  default = "500"
}
