variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana (leave empty to auto-generate)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_grafana_loadbalancer" {
  description = "Enable LoadBalancer for Grafana (set to false for NodePort to save costs)"
  type        = bool
  default     = true
}

variable "prometheus_retention" {
  description = "Prometheus data retention period"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Prometheus persistent volume size"
  type        = string
  default     = "50Gi"
}

variable "loki_storage_size" {
  description = "Loki persistent volume size"
  type        = string
  default     = "30Gi"
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
