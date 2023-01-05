
output "talosconfig" {
  value     = talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig.kube_config
  sensitive = true
}
