resource "oci_core_drg" "drg" {
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  display_name  = "${var.cluster_name}-drg"
  freeform_tags = local.common_labels
}
resource "oci_core_vcn" "vcn" {
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  cidr_blocks    = var.cidr_blocks
  display_name   = "${var.cluster_name}-vcn"
  freeform_tags  = local.common_labels
  is_ipv6enabled = true
}
resource "oci_core_subnet" "subnet" {
  #Required
  cidr_block                 = var.subnet_block
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
  availability_domain        = var.instance_availability_domain == null ? data.oci_identity_availability_domains.availability_domains.availability_domains[0].name : var.instance_availability_domain

  #Optional
  display_name      = "${var.cluster_name}-subnet"
  freeform_tags     = local.common_labels
  security_list_ids = [oci_core_security_list.security_list.id]
  route_table_id    = oci_core_route_table.route_table.id
}
resource "oci_core_subnet" "subnet_regional" {
  #Required
  cidr_block                 = var.subnet_block_regional
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.vcn.id
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false

  #Optional
  display_name      = "${var.cluster_name}-subnet-regional"
  freeform_tags     = local.common_labels
  security_list_ids = [oci_core_security_list.security_list.id]
  route_table_id    = oci_core_route_table.route_table.id
}
resource "oci_core_route_table" "route_table" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name  = "${var.cluster_name}-route-table"
  freeform_tags = local.common_labels
  route_rules {
    #Required
    network_entity_id = oci_core_internet_gateway.internet_gateway.id

    #Optional
    destination_type = "CIDR_BLOCK"
    destination      = "0.0.0.0/0"
  }
}

resource "oci_core_internet_gateway" "internet_gateway" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  enabled       = true
  display_name  = "${var.cluster_name}-internet-gateway"
  freeform_tags = local.common_labels
}

resource "oci_core_network_security_group" "network_security_group" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name  = "${var.cluster_name}-security-group"
  freeform_tags = local.common_labels
}
resource "oci_core_network_security_group_security_rule" "allow_all" {
  network_security_group_id = oci_core_network_security_group.network_security_group.id
  destination_type          = "CIDR_BLOCK"
  destination               = "0.0.0.0/0"
  protocol                  = "all"
  direction                 = "EGRESS"
  stateless                 = false
}

resource "oci_core_security_list" "security_list" {
  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name = "${var.cluster_name}-security-list"
  egress_security_rules {
    #Required
    destination = "0.0.0.0/0"
    protocol    = "all"

    stateless = true
  }
  freeform_tags = local.common_labels
  ingress_security_rules {
    #Required
    source   = "0.0.0.0/0"
    protocol = "all"

    stateless = true
  }
}

resource "oci_network_load_balancer_network_load_balancer" "controlplane_load_balancer" {
  depends_on = [oci_core_security_list.security_list, oci_core_vcn.vcn]

  #Required
  compartment_id             = var.compartment_ocid
  display_name               = "${var.cluster_name}-controlplane-load-balancer"
  subnet_id                  = oci_core_subnet.subnet.id
  network_security_group_ids = [oci_core_network_security_group.network_security_group.id]

  #Optional
  freeform_tags                  = local.common_labels
  is_preserve_source_destination = false
  is_private                     = false

  lifecycle {
    ignore_changes = [
      defined_tags,
    ]
  }
}
resource "oci_network_load_balancer_backend_set" "talos_backend_set" {
  #Required
  name                     = "${var.cluster_name}-talos"
  policy                   = "FIVE_TUPLE"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.id
  health_checker {
    #Required
    protocol = "TCP"
    port     = 50000
    #Optional
    interval_in_millis = 10000
  }
  #Optional
  is_preserve_source = false
}
resource "oci_network_load_balancer_listener" "talos_listener" {
  #Required
  default_backend_set_name = oci_network_load_balancer_backend_set.talos_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.id
  name                     = "${var.cluster_name}-talos"
  port                     = 50000
  protocol                 = "TCP"
}
resource "oci_network_load_balancer_backend_set" "controlplane_backend_set" {
  #Required
  name                     = "${var.cluster_name}-controlplane"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.id
  policy                   = "FIVE_TUPLE"
  health_checker {
    #Required
    protocol = "TCP"
    port     = 6443
    #Optional
    interval_in_millis = 10000
  }
  #Optional
  is_preserve_source = false
}
resource "oci_network_load_balancer_listener" "controlplane_listener" {
  #Required
  default_backend_set_name = oci_network_load_balancer_backend_set.controlplane_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.id
  name                     = "${var.cluster_name}-controlplane"
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend" "controlplane_backend" {
  for_each = { for idx, val in oci_core_instance.controlplane : idx => val }
  #Required
  backend_set_name         = oci_network_load_balancer_backend_set.controlplane_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.id
  port                     = 6443

  #Optional
  target_id = each.value.id
}

resource "oci_network_load_balancer_backend" "talos_backend" {
  for_each = { for idx, val in oci_core_instance.controlplane : idx => val }
  #Required
  backend_set_name         = oci_network_load_balancer_backend_set.talos_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.controlplane_load_balancer.id
  port                     = 50000

  #Optional
  target_id = each.value.id
}
