resource "oci_nosql_table" "toggle_master_analytics" {
  compartment_id = var.compartment_id
  name           = "ToggleMasterAnalytics"
  ddl_statement  = <<-EOT
    CREATE TABLE IF NOT EXISTS ToggleMasterAnalytics (
      id STRING,
      feature_name STRING,
      enabled BOOLEAN,
      user_id STRING,
      event_timestamp TIMESTAMP(3),
      metadata JSON,
      PRIMARY KEY (id)
    )
  EOT

  table_limits {
    max_read_units     = var.nosql_read_units
    max_write_units    = var.nosql_write_units
    max_storage_in_gbs = var.nosql_storage_gb
  }

  is_auto_reclaimable = false

  freeform_tags = merge(local.common_tags, {
    Table = "ToggleMasterAnalytics"
  })
}
