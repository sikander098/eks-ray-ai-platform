# Monitoring Namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    
    labels = {
      name       = "monitoring"
      managed-by = "terraform"
    }
  }
}

# Generate Grafana admin password
resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

# Grafana admin password secret
resource "kubernetes_secret" "grafana_admin" {
  metadata {
    name      = "grafana-admin-credentials"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    admin-user     = "admin"
    admin-password = var.grafana_admin_password != "" ? var.grafana_admin_password : random_password.grafana_admin.result
  }

  type = "Opaque"
}

# Helm Release: kube-prometheus-stack (Prometheus + Grafana + AlertManager)
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [yamlencode({
    prometheus = {
      prometheusSpec = {
        retention = var.prometheus_retention
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              accessModes = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.prometheus_storage_size
                }
              }
            }
          }
        }
        # Enable service monitors for automatic scraping
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
      }
    }

    grafana = {
      enabled = true
      
      # Use existing secret for admin credentials
      admin = {
        existingSecret = kubernetes_secret.grafana_admin.metadata[0].name
        userKey        = "admin-user"
        passwordKey    = "admin-password"
      }

      # Service configuration
      service = {
        type = var.enable_grafana_loadbalancer ? "LoadBalancer" : "NodePort"
        port = 80
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          "service.beta.kubernetes.io/aws-load-balancer-type"   = "nlb"
        }
      }

      # Persistence for dashboards
      persistence = {
        enabled = true
        size    = "10Gi"
      }

      # Auto-configure datasources
      additionalDataSources = [
        {
          name      = "Prometheus"
          type      = "prometheus"
          url       = "http://kube-prometheus-stack-prometheus:9090"
          access    = "proxy"
          jsonData = {
            timeInterval = "30s"
          }
        },
        {
          name   = "Loki"
          type   = "loki"
          url    = "http://loki:3100"
          access = "proxy"
          jsonData = {
            maxLines = 1000
            derivedFields = [
              {
                datasourceUid = "Tempo"
                matcherRegex  = "(?:traceID|trace_id)=(\\w+)"
                name          = "TraceID"
                url           = "$${__value.raw}"
              }
            ]
          }
        },
        {
          name   = "Tempo"
          type   = "tempo"
          url    = "http://tempo:3100"
          access = "proxy"
          jsonData = {
            tracesToLogs = {
              datasourceUid = "loki"
              tags          = ["job", "instance", "pod", "namespace"]
            }
            serviceMap = {
              datasourceUid = "prometheus"
            }
            nodeGraph = {
              enabled = true
            }
          }
        }
      ]
    }

    # AlertManager configuration
    alertmanager = {
      enabled = true
    }
  })]

  depends_on = [kubernetes_secret.grafana_admin]
}

# Helm Release: Loki (Log Aggregation)
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "5.41.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [yamlencode({
    deploymentMode = "SingleBinary"

    loki = {
      auth_enabled = false
      
      commonConfig = {
        replication_factor = 1
      }

      storage = {
        type = "s3"
        bucketNames = {
          chunks = aws_s3_bucket.loki_logs.id
          ruler  = aws_s3_bucket.loki_logs.id
          admin  = aws_s3_bucket.loki_logs.id
        }
        s3 = {
          region = data.aws_region.current.name
        }
      }

      schemaConfig = {
        configs = [{
          from         = "2024-04-01"
          store        = "tsdb"
          object_store = "s3"
          schema       = "v13"
          index = {
            prefix = "index_"
            period = "24h"
          }
        }]
      }
    }

    singleBinary = {
      replicas = 1
      
      persistence = {
        enabled = true
        size    = var.loki_storage_size
      }
    }

    serviceAccount = {
      create = true
      name   = "loki"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.loki_irsa.iam_role_arn
      }
    }

    # Disable components not needed in monolithic mode
    backend = { replicas = 0 }
    read    = { replicas = 0 }
    write   = { replicas = 0 }
  })]

  depends_on = [helm_release.kube_prometheus_stack]
}

# Helm Release: Promtail (Log Shipper)
resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.15.3"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [yamlencode({
    config = {
      clients = [
        {
          url = "http://loki:3100/loki/api/v1/push"
        }
      ]
    }

    daemonset = {
      enabled = true
    }
  })]

  depends_on = [helm_release.loki]
}

# Helm Release: Tempo (Distributed Tracing)
resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  version    = "1.7.1"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [yamlencode({
    tempo = {
      receivers = {
        otlp = {
          protocols = {
            grpc = { endpoint = "0.0.0.0:4317" }
            http = { endpoint = "0.0.0.0:4318" }
          }
        }
      }

      storage = {
        trace = {
          backend = "s3"
          s3 = {
            bucket = aws_s3_bucket.tempo_traces.id
            endpoint = "s3.${data.aws_region.current.name}.amazonaws.com"
            region   = data.aws_region.current.name
          }
        }
      }
    }

    serviceAccount = {
      create = true
      name   = "tempo"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.tempo_irsa.iam_role_arn
      }
    }

    persistence = {
      enabled = true
      size    = "10Gi"
    }

    service = {
      type = "ClusterIP"
    }
  })]

  depends_on = [helm_release.kube_prometheus_stack]
}
