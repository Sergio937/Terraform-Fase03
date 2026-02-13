resource "oci_queue_queue" "main" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}-queue"

  dead_letter_queue_delivery_count = var.queue_dead_letter_count
  retention_in_seconds             = var.queue_retention_seconds
  timeout_in_seconds               = var.queue_timeout_seconds
  visibility_in_seconds            = var.queue_visibility_seconds

  freeform_tags = merge(local.common_tags, {
    Service = "messaging"
  })
}
