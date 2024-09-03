output "talosconfig" {
  description = "The generated talosconfig."
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "The generated kubeconfig."
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}
