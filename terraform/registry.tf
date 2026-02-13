resource "oci_artifacts_container_repository" "api_gateway" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}/analytics-service"
  is_public      = false
  is_immutable   = false
}

resource "oci_artifacts_container_repository" "user_service" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}/auth-service"
  is_public      = false
  is_immutable   = false
}

resource "oci_artifacts_container_repository" "order_service" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}/evaluation-service"
  is_public      = false
  is_immutable   = false
}

resource "oci_artifacts_container_repository" "payment_service" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}/flag-service"
  is_public      = false
  is_immutable   = false
}

resource "oci_artifacts_container_repository" "notification_service" {
  compartment_id = var.compartment_id
  display_name   = "${var.project_name}/targeting-service"
  is_public      = false
  is_immutable   = false
}
