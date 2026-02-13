output "oke_vcn_id" {
  description = "OCID da VCN"
  value       = oci_core_vcn.oke.id
}

output "public_subnet_ids" {
  description = "Subnets públicas (API e LB)"
  value = [
    oci_core_subnet.oke_api.id,
    oci_core_subnet.oke_lb.id
  ]
}

output "private_subnet_ids" {
  description = "Subnets privadas (Workers, Pods, DB)"
  value = [
    oci_core_subnet.oke_workers.id,
    oci_core_subnet.oke_pods.id,
    oci_core_subnet.oke_db.id
  ]
}

output "oke_cluster_id" {
  description = "OCID do OKE cluster"
  value       = oci_containerengine_cluster.main.id
}

output "oke_node_pool_id" {
  description = "OCID do node pool"
  value       = oci_containerengine_node_pool.main.id
}

output "postgres_db_system_ids" {
  description = "OCIDs dos 3 DB Systems PostgreSQL"
  value       = oci_psql_db_system.postgres[*].id
}

output "redis_cluster_id" {
  description = "OCID do Redis Cluster"
  value       = oci_redis_redis_cluster.main.id
}

output "redis_primary_fqdn" {
  description = "FQDN principal do Redis"
  value       = oci_redis_redis_cluster.main.primary_fqdn
}

output "nosql_table_id" {
  description = "OCID da tabela ToggleMasterAnalytics"
  value       = oci_nosql_table.toggle_master_analytics.id
}

output "queue_id" {
  description = "OCID da fila"
  value       = oci_queue_queue.main.id
}

output "queue_messages_endpoint" {
  description = "Endpoint da fila"
  value       = oci_queue_queue.main.messages_endpoint
}

output "repository_ids" {
  description = "OCIDs dos 5 repositórios OCIR"
  value = {
    api_gateway          = oci_artifacts_container_repository.api_gateway.id
    user_service         = oci_artifacts_container_repository.user_service.id
    order_service        = oci_artifacts_container_repository.order_service.id
    payment_service      = oci_artifacts_container_repository.payment_service.id
    notification_service = oci_artifacts_container_repository.notification_service.id
  }
}
