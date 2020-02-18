resource "oci_core_vcn" "hub" {
  cidr_block     = "10.0.0.0/16"
  dns_label      = "hub"
  compartment_id = var.compartment_ocid
  display_name   = "hub"
}

#IGW
resource "oci_core_internet_gateway" "hub_internet_gateway" {
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.hub.id
    enabled = "true"
    display_name = "IGW_HUB"
}

#DRG
# resource "oci_core_drg" "hub_drg" {
#     compartment_id = var.compartment_ocid
#     display_name = "HUB_DRG"
# }

# resource "oci_core_drg_attachment" "hub_drg_attachment" {
#     #Required
#     drg_id = oci_core_drg.hub_drg.id
#     vcn_id = oci_core_vcn.hub.id

#     #Optional
#     # display_name = "${var.drg_attachment_display_name}"
#     # route_table_id = "${oci_core_route_table.test_route_table.id}"
# }


#Default route table hub
resource "oci_core_default_route_table" "hub_default_route_table" {
    manage_default_resource_id = oci_core_vcn.hub.default_route_table_id
    route_rules {
        network_entity_id = oci_core_internet_gateway.hub_internet_gateway.id
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
    }
    route_rules {
        network_entity_id = oci_core_local_peering_gateway.hub_spoke01_local_peering_gateway.id
        destination       = "10.10.0.0/16"
        destination_type  = "CIDR_BLOCK"
    }
    route_rules {
        network_entity_id = oci_core_local_peering_gateway.hub_spoke02_local_peering_gateway.id
        destination       = "10.20.0.0/16"
        destination_type  = "CIDR_BLOCK"
    }
}

# Peering connections to the spokes
resource "oci_core_local_peering_gateway" "hub_spoke01_local_peering_gateway" {
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.hub.id
    display_name = "hub_spoke01"
    peer_id = oci_core_local_peering_gateway.spoke01_hub_local_peering_gateway.id
}

resource "oci_core_local_peering_gateway" "hub_spoke02_local_peering_gateway" {
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.hub.id
    display_name = "hub_spoke02"
    peer_id = oci_core_local_peering_gateway.spoke02_hub_local_peering_gateway.id
}
#Hub pub subnet
resource "oci_core_subnet" "hub_subnet_pub01" {
    cidr_block = "10.0.10.0/24"
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.hub.id
    display_name = "hub_subnet_pub01"
}

# Bastion VM

resource "oci_core_instance" "bastion_instance" {
  # count = var.NumInstances
  availability_domain = data.oci_identity_availability_domain.default_AD.name
  compartment_id = var.compartment_ocid
  display_name = "BastionVM"
  shape = var.InstanceShape

  create_vnic_details {
    subnet_id = oci_core_subnet.hub_subnet_pub01.id
    display_name = "primaryvnic"
    assign_public_ip = true
  }

  source_details {
    source_type = "image"
    source_id = var.InstanceImageOCID[var.region]

  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
  
  }
  # timeouts {
  #   create = "60m"
  # }
}