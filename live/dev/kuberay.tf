# Deploy KubeRay Operator
resource "helm_release" "kuberay_operator" {
  name             = "kuberay-operator"
  repository       = "https://ray-project.github.io/kuberay-helm/"
  chart            = "kuberay-operator"
  version          = "1.0.0"
  namespace        = "ray-system"
  create_namespace = true

  cleanup_on_fail = true
}

# Ray Cluster is managed via kubectl for now because it's a CRD resource
# and often changes more frequently than infra.
