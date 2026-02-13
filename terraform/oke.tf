data "oci_containerengine_node_pool_option" "options" {
  node_pool_option_id = "all"
  compartment_id      = var.compartment_id
}

locals {
  oke_k8s_version_short = replace(var.oke_kubernetes_version, "v", "")
  oke_image_candidates = [
    for source in data.oci_containerengine_node_pool_option.options.sources : source
    if !can(regex("aarch64", source.source_name))
    && !can(regex("GPU", source.source_name))
    && can(regex("OKE-${local.oke_k8s_version_short}", source.source_name))
  ]
  oke_node_image_id = var.oke_node_image_id != "" ? var.oke_node_image_id : local.oke_image_candidates[0].image_id
}

resource "oci_containerengine_cluster" "main" {
  compartment_id     = var.compartment_id
  kubernetes_version = var.oke_kubernetes_version
  name               = "${var.project_name}-oke"
  vcn_id             = oci_core_vcn.oke.id
  type               = "ENHANCED_CLUSTER"

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.oke_api.id
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.oke_lb.id]

    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }

    kubernetes_network_config {
      services_cidr = var.oke_services_cidr
    }
  }

  cluster_pod_network_options {
    cni_type = "OCI_VCN_IP_NATIVE"
  }

  freeform_tags = local.common_tags
}

resource "oci_containerengine_node_pool" "main" {
  cluster_id         = oci_containerengine_cluster.main.id
  compartment_id     = var.compartment_id
  kubernetes_version = var.oke_kubernetes_version
  name               = "${var.project_name}-nodepool"

  node_shape = var.oke_node_shape

  node_shape_config {
    memory_in_gbs = var.oke_node_memory_gb
    ocpus         = var.oke_node_ocpus
  }

  node_config_details {
    size = var.oke_node_count

    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.oke_workers.id
    }

    node_pool_pod_network_option_details {
      cni_type          = "OCI_VCN_IP_NATIVE"
      pod_subnet_ids    = [oci_core_subnet.oke_pods.id]
      max_pods_per_node = 31
      pod_nsg_ids       = []
    }

    freeform_tags = local.common_tags
  }

  node_source_details {
    source_type             = "IMAGE"
    image_id                = local.oke_node_image_id
    boot_volume_size_in_gbs = 50
  }

  initial_node_labels {
    key   = "environment"
    value = var.environment
  }

  ssh_public_key = var.ssh_public_key

  freeform_tags = local.common_tags
}
