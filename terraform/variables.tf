variable "tenancy_ocid" {
  description = "OCID do Tenancy OCI"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "OCID do Usuário OCI"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "Fingerprint da API Key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Região OCI"
  type        = string
  default     = "sa-saopaulo-1"
}

variable "compartment_id" {
  description = "OCID do Compartment"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "fiap-demo-oci"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "ssh_public_key" {
  description = "Chave SSH pública para os nodes OKE"
  type        = string
  sensitive   = true
}

variable "oke_vcn_cidr" {
  description = "CIDR da VCN dedicada para OKE"
  type        = string
  default     = "10.10.0.0/16"
}

variable "oke_subnet_api_cidr" {
  description = "CIDR da subnet do API endpoint OKE"
  type        = string
  default     = "10.10.0.0/28"
}

variable "oke_subnet_workers_cidr" {
  description = "CIDR da subnet de worker nodes OKE"
  type        = string
  default     = "10.10.10.0/24"
}

variable "oke_subnet_lb_cidr" {
  description = "CIDR da subnet para load balancers"
  type        = string
  default     = "10.10.20.0/24"
}

variable "oke_subnet_pods_cidr" {
  description = "CIDR da subnet de pods (VCN native)"
  type        = string
  default     = "10.10.128.0/18"
}

variable "oke_subnet_db_cidr" {
  description = "CIDR da subnet de bancos"
  type        = string
  default     = "10.10.30.0/24"
}

variable "oke_kubernetes_version" {
  description = "Versão Kubernetes do OKE"
  type        = string
  default     = "v1.33.1"
}

variable "oke_node_shape" {
  description = "Shape dos nodes do OKE"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "oke_node_ocpus" {
  description = "OCPUs por node OKE"
  type        = number
  default     = 2
}

variable "oke_node_memory_gb" {
  description = "Memória em GB por node OKE"
  type        = number
  default     = 16
}

variable "oke_node_count" {
  description = "Quantidade de nodes no node pool"
  type        = number
  default     = 2
}

variable "oke_node_image_id" {
  description = "OCID da imagem dos nodes OKE"
  type        = string
  default     = ""
}

variable "oke_services_cidr" {
  description = "CIDR de services do Kubernetes"
  type        = string
  default     = "10.96.0.0/16"
}

variable "postgres_db_system_count" {
  description = "Quantidade de DB Systems PostgreSQL"
  type        = number
  default     = 1
}

variable "postgres_db_version" {
  description = "Versão do PostgreSQL gerenciado"
  type        = string
  default     = "14"
}

variable "postgres_shape" {
  description = "Shape do OCI PostgreSQL"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "postgres_instance_count" {
  description = "Número de nós por DB System PostgreSQL"
  type        = number
  default     = 1
}

variable "postgres_instance_memory_size_in_gbs" {
  description = "Memória por nó PostgreSQL"
  type        = number
  default     = 16
}

variable "postgres_instance_ocpu_count" {
  description = "OCPUs por nó PostgreSQL"
  type        = number
  default     = 2
}

variable "postgres_storage_system_type" {
  description = "Tipo de storage do PostgreSQL"
  type        = string
  default     = "OCI_OPTIMIZED_STORAGE"
}

variable "postgres_admin_username" {
  description = "Usuário admin do PostgreSQL"
  type        = string
  default     = "pgadmin"
}

variable "postgres_admin_password" {
  description = "Senha admin do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "redis_node_count" {
  description = "Quantidade de nós do Redis"
  type        = number
  default     = 1
}

variable "redis_node_memory_in_gbs" {
  description = "Memória por nó Redis em GB"
  type        = number
  default     = 2
}

variable "redis_software_version" {
  description = "Versão do software Redis"
  type        = string
  default     = "V7_0_5"
}

variable "nosql_read_units" {
  description = "Read units da NoSQL"
  type        = number
  default     = 50
}

variable "nosql_write_units" {
  description = "Write units da NoSQL"
  type        = number
  default     = 50
}

variable "nosql_storage_gb" {
  description = "Storage da NoSQL em GB"
  type        = number
  default     = 25
}

variable "queue_retention_seconds" {
  description = "Retenção das mensagens na queue"
  type        = number
  default     = 345600
}

variable "queue_timeout_seconds" {
  description = "Timeout de processamento da queue"
  type        = number
  default     = 30
}

variable "queue_visibility_seconds" {
  description = "Visibility timeout da queue"
  type        = number
  default     = 30
}

variable "queue_dead_letter_count" {
  description = "Tentativas antes de descarte"
  type        = number
  default     = 5
}
