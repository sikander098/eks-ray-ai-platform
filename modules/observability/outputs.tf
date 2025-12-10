output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}

output "grafana_service_type" {
  description = "Grafana service type"
  value       = var.enable_grafana_loadbalancer ? "LoadBalancer" : "NodePort"
}

output "prometheus_endpoint" {
  description = "Prometheus endpoint"
  value       = "http://kube-prometheus-stack-prometheus.monitoring:9090"
}

output "loki_endpoint" {
  description = "Loki endpoint"
  value       = "http://loki.monitoring:3100"
}

output "tempo_endpoint" {
  description = "Tempo endpoint"
  value       = "http://tempo.monitoring:3100"
}

output "tempo_otlp_grpc_endpoint" {
  description = "Tempo OTLP gRPC endpoint for trace ingestion"
  value       = "tempo.monitoring:4317"
}

output "tempo_otlp_http_endpoint" {
  description = "Tempo OTLP HTTP endpoint for trace ingestion"
  value       = "http://tempo.monitoring:4318"
}

output "grafana_url_command" {
  description = "Command to get Grafana URL"
  value       = var.enable_grafana_loadbalancer ? "kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'" : "kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.spec.ports[0].nodePort}'"
}
