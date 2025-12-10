# Deploy JupyterHub
resource "helm_release" "jupyterhub" {
  name             = "jupyterhub"
  repository       = "https://hub.jupyter.org/helm-chart/"
  chart            = "jupyterhub"
  version          = "3.2.1"
  namespace        = "jupyterhub"
  create_namespace = true

  values = [
    <<EOF
hub:
  config:
    Authenticator:
      admin_users:
        - admin
    DummyAuthenticator:
      password: "password"
    JupyterHub:
      authenticator_class: dummy

proxy:
  service:
    type: LoadBalancer

singleuser:
  image:
    name: rayproject/ray
    tag: "2.9.0"
  cmd: ["jupyterhub-singleuser"]
  extraEnv:
    RAY_ADDRESS: "ray://ray-cluster-kuberay-head-svc.ray-system.svc.cluster.local:10001"
  profileList:
    - display_name: "Default Environment (Ray Client)"
      default: true
      kubespawner_override:
        cpu_limit: 1
        mem_limit: 2G
EOF
  ]

  cleanup_on_fail = true
}
