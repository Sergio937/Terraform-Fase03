resource "oci_psql_db_system" "postgres" {
  count = var.postgres_db_system_count

  compartment_id = var.compartment_id
  db_version     = var.postgres_db_version
  display_name   = "${var.project_name}-postgres-${count.index + 1}"
  shape          = var.postgres_shape

  credentials {
    username = var.postgres_admin_username

    password_details {
      password_type = "PLAIN_TEXT"
      password      = var.postgres_admin_password
    }
  }

  network_details {
    subnet_id = oci_core_subnet.oke_db.id
  }

  storage_details {
    is_regionally_durable = true
    system_type           = var.postgres_storage_system_type
  }

  instance_count              = var.postgres_instance_count
  instance_memory_size_in_gbs = var.postgres_instance_memory_size_in_gbs
  instance_ocpu_count         = var.postgres_instance_ocpu_count

  freeform_tags = merge(local.common_tags, {
    Service = "postgresql"
  })
}

resource "oci_redis_redis_cluster" "main" {
  compartment_id     = var.compartment_id
  display_name       = "${var.project_name}-redis"
  node_count         = var.redis_node_count
  node_memory_in_gbs = var.redis_node_memory_in_gbs
  software_version   = var.redis_software_version
  subnet_id          = oci_core_subnet.oke_db.id

  freeform_tags = merge(local.common_tags, {
    Service = "redis"
  })
}
