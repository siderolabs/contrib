resource "oci_identity_dynamic_group" "oci-ccm" {
  #Required
  name           = "${var.cluster_name}-oci-ccm"
  compartment_id = var.tenancy_ocid # tenancy_ocid, compartment_ocid and domain_ocid doesn't work
  description    = "Instance access"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"

  #Optional
  freeform_tags = local.common_labels
}

locals {
  ns_type_name   = strcontains(var.compartment_ocid, ".tenancy.") ? "tenancy" : "compartment"
  ns_select_name = strcontains(var.compartment_ocid, ".compartment.") ? data.oci_identity_compartment.this.name : ""
}

resource "oci_identity_policy" "oci-ccm" {
  #Required
  name           = "${var.cluster_name}-oci-ccm"
  compartment_id = var.tenancy_ocid
  description    = "Instance access"
  statements = [
    // LoadBalancer Services
    "Allow dynamic-group ${oci_identity_dynamic_group.oci-ccm.name} to read instance-family in ${local.ns_type_name} ${local.ns_select_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.oci-ccm.name} to use virtual-network-family in ${local.ns_type_name} ${local.ns_select_name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.oci-ccm.name} to manage load-balancers in ${local.ns_type_name} ${local.ns_select_name}",
  ]

  #Optional
  freeform_tags = local.common_labels
}
