output "factory_disk_image" {
  value = data.talos_image_factory_urls.this.urls.disk_image
}

output "load_balancer_ip" {
  value = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.ip_addresses[0].ip_address
}

output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}

output "oci_cloud_provider_config" {
  value     = local.oci_cloud_provider_config
  sensitive = true
}
