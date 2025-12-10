# Cilium CNI Migration & Installation
# Replaces AWS VPC CNI and Kube-Proxy with Cilium eBPF
# -----------------------------------------------------

# 1. REMOVE LEGACY CNI (The "Blackout" Switch)
# We must delete the AWS CNI and Kube-Proxy DaemonSets to allow Cilium to take over.
# This runs locally on the machine executing Terraform.
resource "null_resource" "remove_legacy_cni" {
  triggers = {
    # Run this only once, or change value to re-run
    migration_id = "v1-migration"
  }

  provisioner "local-exec" {
    command = <<EOT
      aws eks update-kubeconfig --region us-east-1 --name astronomy-dev
      kubectl -n kube-system delete daemonset aws-node --ignore-not-found
      kubectl -n kube-system delete daemonset kube-proxy --ignore-not-found
    EOT
  }

  depends_on = [module.eks]
}

# 2. INSTALL CILIUM (The Resurrection)
resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  namespace  = "kube-system"
  version    = "1.18.4" # Matches installed version

  # Wait for legacy CNI removal
  depends_on = [
    module.eks,
    null_resource.remove_legacy_cni
  ]

  # EKS-Specific Configuration
  set {
    name  = "eni.enabled"
    value = "true"
  }
  set {
    name  = "ipam.mode"
    value = "eni"
  }
  set {
    name  = "egressMasqueradeInterfaces"
    value = "eth0"
  }
  set {
    name  = "routingMode"
    value = "native"
  }

  set {
    name  = "autoDirectNodeRoutes"
    value = "true"
  }

  # eBPF Kube-Proxy Replacement (Performance)
  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }
  set {
    name  = "k8sServiceHost"
    value = replace(module.eks.cluster_endpoint, "https://", "")
  }
  set {
    name  = "k8sServicePort"
    value = "443"
  }

  # Observability (Hubble)
  set {
    name  = "hubble.enabled"
    value = "true"
  }
  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }
  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }
}
