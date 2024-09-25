resource "random_pet" "controlplane" {
  count     = var.controlplane_instance_count
  length    = 2
  separator = "-"
}
resource "random_pet" "worker" {
  count     = var.worker_instance_count
  length    = 2
  separator = "-"
}

resource "oci_core_instance" "controlplane" {
  for_each = { for idx, val in random_pet.controlplane : idx => val }
  # count = 1
  #Required
  # choose the next availability domain which wasn't last
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[each.key % length(data.oci_identity_availability_domains.availability_domains.availability_domains)].name
  compartment_id      = var.compartment_ocid
  shape               = var.instance_shape == null ? data.oci_core_image_shapes.image_shapes.image_shape_compatibilities[0].shape : var.instance_shape
  shape_config {
    ocpus         = var.controlplane_instance_ocpus
    memory_in_gbs = var.controlplane_instance_memory_in_gbs
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.subnet_regional.id
    nsg_ids          = [oci_core_network_security_group.network_security_group.id]
  }
  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }
  availability_config {
    is_live_migration_preferred = true
    recovery_action             = "RESTORE_INSTANCE"
  }
  #Optional
  display_name  = "${var.cluster_name}-control-plane-${each.value.id}"
  freeform_tags = local.common_labels
  launch_options {
    #Optional
    network_type            = local.instance_mode
    remote_data_volume_type = local.instance_mode
    boot_volume_type        = local.instance_mode
    firmware                = "UEFI_64"
  }
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }
  source_details {
    #Required
    source_type             = "image"
    source_id               = oci_core_image.talos_image.id
    boot_volume_size_in_gbs = "50"
  }
  preserve_boot_volume = false

  lifecycle {
    create_before_destroy = "true"
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_instance" "worker" {
  for_each = { for idx, val in random_pet.worker : idx => val }
  # count = 1
  #Required
  # choose the next availability domain which wasn't last
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[each.key % length(data.oci_identity_availability_domains.availability_domains.availability_domains)].name
  compartment_id      = var.compartment_ocid
  shape               = var.instance_shape == null ? data.oci_core_image_shapes.image_shapes.image_shape_compatibilities[0].shape : var.instance_shape
  shape_config {
    ocpus         = var.worker_instance_ocpus
    memory_in_gbs = var.worker_instance_memory_in_gbs
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.subnet_regional.id
    nsg_ids          = [oci_core_network_security_group.network_security_group.id]
  }
  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }
  availability_config {
    is_live_migration_preferred = true
    recovery_action             = "RESTORE_INSTANCE"
  }
  #Optional
  display_name  = "${var.cluster_name}-worker-${each.value.id}"
  freeform_tags = local.common_labels
  launch_options {
    #Optional
    network_type            = local.instance_mode
    remote_data_volume_type = local.instance_mode
    boot_volume_type        = local.instance_mode
    firmware                = "UEFI_64"
  }
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }
  source_details {
    #Required
    source_type             = "image"
    source_id               = oci_core_image.talos_image.id
    boot_volume_size_in_gbs = "50"
  }
  preserve_boot_volume = false

  lifecycle {
    create_before_destroy = "true"
    ignore_changes = [
      defined_tags
    ]
  }
}
