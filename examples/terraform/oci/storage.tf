resource "oci_core_volume" "worker" {
  for_each = { for idx, val in oci_core_instance.worker : idx => val if var.worker_volume_enabled }
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[each.key % length(data.oci_identity_availability_domains.availability_domains.availability_domains)].name
  display_name        = each.value.display_name
  freeform_tags       = local.common_labels
  size_in_gbs         = var.worker_volume_size_in_gbs

  lifecycle {
    create_before_destroy = "true"
    ignore_changes = [
      defined_tags
    ]
  }
}

resource "oci_core_volume_attachment" "worker_volume_attachment" {
  for_each = { for idx, val in oci_core_volume.worker : idx => val if var.worker_volume_enabled }
  #Required
  attachment_type = local.instance_mode
  instance_id     = [for val in oci_core_instance.worker : val if val.display_name == each.value.display_name][0].id
  volume_id       = each.value.id

  lifecycle {
    create_before_destroy = "true"
  }
}
