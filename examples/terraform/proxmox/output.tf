output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.this.kubeconfig_raw 
  sensitive = true
}

output "controlplaneconfig" {
  value     = yamlencode(data.talos_machine_configuration.controlplane) 
  sensitive = true
}

output "workerconfig" {
  value     = yamlencode(data.talos_machine_configuration.worker) 
  sensitive = true
}

