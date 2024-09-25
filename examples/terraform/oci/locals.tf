locals {
  common_labels = {
    "TalosCluster" = var.cluster_name
  }
  talos_install_image         = data.talos_image_factory_urls.this.urls.installer
  instance_mode               = "PARAVIRTUALIZED"
  talos_install_disk          = "/dev/sda"
  instance_kernel_arg_console = "ttyAMA0"
  # Example: https://raw.githubusercontent.com/oracle/oci-cloud-controller-manager/v1.26.0/manifests/provider-config-instance-principals-example.yaml
  oci_config_ini            = <<EOF
[Global]
compartment-id = ${var.compartment_ocid}
region = ${var.region}
use-instance-principals = true
EOF
  oci_cloud_provider_config = <<EOF
auth:
  useInstancePrincipals: true
compartment: ${var.compartment_ocid}
vcn: ${oci_core_vcn.vcn.id}
loadBalancer:
  subnet1: ${oci_core_subnet.subnet_regional.id}
  securityListManagementMode: None
  securityLists:
    ${oci_core_subnet.subnet_regional.id}: ${oci_core_security_list.security_list.id}
EOF

  talos_base_configuration = <<-EOT
    machine:
       sysctls:
         user.max_user_namespaces: "11255"
       time:
         servers:
           - 169.254.169.254
       kubelet:
         extraArgs:
           cloud-provider: external
           rotate-server-certificates: "true"
       systemDiskEncryption:
         state:
           provider: luks2
           keys:
             - nodeID: {}
               slot: 0
         ephemeral:
           provider: luks2
           keys:
             - nodeID: {}
               slot: 0
           options:
             - no_read_workqueue
             - no_write_workqueue
       features:
         kubePrism:
           enabled: true
           port: 7445
       install:
         disk: ${local.talos_install_disk}
         extraKernelArgs:
            - console=console=${local.instance_kernel_arg_console}
            - talos.platform=oracle
         wipe: false
         image: ${local.talos_install_image}
    cluster:
       discovery:
         enabled: true
       network:
         podSubnets:
           - ${var.pod_subnet_block}
         serviceSubnets:
           - ${var.service_subnet_block}
       allowSchedulingOnMasters: false
       externalCloudProvider:
         enabled: true
         manifests:
           - https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/${var.talos_ccm_version}/docs/deploy/cloud-controller-manager.yml
           - https://github.com/oracle/oci-cloud-controller-manager/releases/download/${var.oracle_cloud_ccm_version}/oci-cloud-controller-manager-rbac.yaml
           - https://github.com/oracle/oci-cloud-controller-manager/releases/download/${var.oracle_cloud_ccm_version}/oci-cloud-controller-manager.yaml
       controllerManager:
         extraArgs:
           cloud-provider: external
       apiServer:
         extraArgs:
           cloud-provider: external
           anonymous-auth: true
       inlineManifests:
         - name: oci-cloud-controller-manager
           contents: |
             apiVersion: v1
             data:
               cloud-provider.yaml: ${base64encode(local.oci_cloud_provider_config)}
               config.ini: ${base64encode(local.oci_config_ini)}
             kind: Secret
             metadata:
               name: oci-cloud-controller-manager
               namespace: kube-system
    EOT
}
