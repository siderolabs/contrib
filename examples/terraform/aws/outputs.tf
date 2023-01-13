output "talosconfig" {
  value     = talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kube_config
  sensitive = true
}
