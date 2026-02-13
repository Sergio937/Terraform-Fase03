resource "oci_core_vcn" "oke" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-oke-vcn"
  cidr_blocks    = [var.oke_vcn_cidr]
  dns_label      = "okevcn"

  freeform_tags = merge(local.common_tags, {
    Purpose = "OKE"
  })
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_internet_gateway" "oke" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.project_name}-oke-igw"
  enabled        = true

  freeform_tags = local.common_tags
}

resource "oci_core_nat_gateway" "oke" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.project_name}-oke-nat"

  freeform_tags = local.common_tags
}

resource "oci_core_service_gateway" "oke" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.project_name}-oke-sgw"

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }

  freeform_tags = local.common_tags
}

resource "oci_core_route_table" "oke_public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.project_name}-oke-rt-public"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.oke.id
  }

  freeform_tags = local.common_tags
}

resource "oci_core_route_table" "oke_private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.project_name}-oke-rt-private"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.oke.id
  }

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.oke.id
  }

  freeform_tags = local.common_tags
}

resource "oci_core_security_list" "oke_api" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.project_name}-oke-sl-api"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.oke_vcn_cidr
    tcp_options {
      min = 12250
      max = 12250
    }
  }

  ingress_security_rules {
    protocol = "1"
    source   = var.oke_vcn_cidr
  }

  freeform_tags = local.common_tags
}

resource "oci_core_security_list" "oke_workers" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.project_name}-oke-sl-workers"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.oke_vcn_cidr
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.oke_vcn_cidr
    tcp_options {
      min = 10250
      max = 10250
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 30000
      max = 32767
    }
  }

  freeform_tags = local.common_tags
}

resource "oci_core_security_list" "oke_lb" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.project_name}-oke-sl-lb"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  freeform_tags = local.common_tags
}

resource "oci_core_security_list" "oke_pods" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.project_name}-oke-sl-pods"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.oke_vcn_cidr
  }

  freeform_tags = local.common_tags
}

resource "oci_core_security_list" "oke_db" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.oke.id
  display_name   = "${var.project_name}-oke-sl-db"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.oke_vcn_cidr
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.oke_vcn_cidr
    tcp_options {
      min = 5432
      max = 5432
    }
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.oke_vcn_cidr
    tcp_options {
      min = 6379
      max = 6379
    }
  }

  freeform_tags = local.common_tags
}

resource "oci_core_subnet" "oke_api" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.oke.id
  display_name               = "${var.project_name}-oke-subnet-api"
  cidr_block                 = var.oke_subnet_api_cidr
  route_table_id             = oci_core_route_table.oke_public.id
  security_list_ids          = [oci_core_security_list.oke_api.id]
  dns_label                  = "okeapi"
  prohibit_public_ip_on_vnic = false

  freeform_tags = merge(local.common_tags, { Purpose = "OKE-API-Endpoint" })
}

resource "oci_core_subnet" "oke_workers" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.oke.id
  display_name               = "${var.project_name}-oke-subnet-workers"
  cidr_block                 = var.oke_subnet_workers_cidr
  route_table_id             = oci_core_route_table.oke_private.id
  security_list_ids          = [oci_core_security_list.oke_workers.id]
  dns_label                  = "okeworkers"
  prohibit_public_ip_on_vnic = true

  freeform_tags = merge(local.common_tags, { Purpose = "OKE-Workers" })
}

resource "oci_core_subnet" "oke_lb" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.oke.id
  display_name               = "${var.project_name}-oke-subnet-lb"
  cidr_block                 = var.oke_subnet_lb_cidr
  route_table_id             = oci_core_route_table.oke_public.id
  security_list_ids          = [oci_core_security_list.oke_lb.id]
  dns_label                  = "okelb"
  prohibit_public_ip_on_vnic = false

  freeform_tags = merge(local.common_tags, { Purpose = "OKE-LoadBalancer" })
}

resource "oci_core_subnet" "oke_pods" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.oke.id
  display_name               = "${var.project_name}-oke-subnet-pods"
  cidr_block                 = var.oke_subnet_pods_cidr
  route_table_id             = oci_core_route_table.oke_private.id
  security_list_ids          = [oci_core_security_list.oke_pods.id]
  dns_label                  = "okepods"
  prohibit_public_ip_on_vnic = true

  freeform_tags = merge(local.common_tags, { Purpose = "OKE-Pods" })
}

resource "oci_core_subnet" "oke_db" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.oke.id
  display_name               = "${var.project_name}-oke-subnet-db"
  cidr_block                 = var.oke_subnet_db_cidr
  route_table_id             = oci_core_route_table.oke_private.id
  security_list_ids          = [oci_core_security_list.oke_db.id]
  dns_label                  = "okedb"
  prohibit_public_ip_on_vnic = true

  freeform_tags = merge(local.common_tags, { Purpose = "Databases" })
}
