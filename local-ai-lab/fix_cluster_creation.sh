#!/bin/bash
set -e

echo "🚒 Emergency Fix: Recreating Cluster with Env Vars..."

# 1. Update config to be safe
cat <<EOF > kind-gpu-fix.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
    - hostPath: /dev/null
      containerPath: /dev/null
    - hostPath: /var/lib/kubelet/device-plugins
      containerPath: /var/lib/kubelet/device-plugins
EOF

# 2. Delete
kind delete cluster --name ai-platform || true

# 3. Create with Env Vars (The Magic Fix)
# We must pass these to the 'kind create' command so the container runtime
# knows to attach the GPU hooks to the node container effectively.
KIND_EXPERIMENTAL_PROVIDER=docker \
kind create cluster --name ai-platform --config kind-gpu-fix.yaml

# 4. Re-install Device Plugin
kubectl create namespace nvidia-device-plugin || true
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: time-slicing-config
  namespace: nvidia-device-plugin
data:
  any-name-works.yaml: |-
    version: v1
    flags:
      migStrategy: none
    sharing:
      timeSlicing:
        resources:
        - name: nvidia.com/gpu
          replicas: 4
EOF

helm upgrade --install nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia-device-plugin \
  --create-namespace \
  --version 0.14.3 \
  --set config.name=time-slicing-config

echo "⏳ Waiting for Device Plugin..."
kubectl rollout status ds/nvdp-nvidia-device-plugin -n nvidia-device-plugin

echo "✅ Done. Verifying capacity..."
echo "Waiting for node capacity update..."
sleep 15
kubectl get node -o jsonpath='{.items[0].status.capacity.nvidia\.com/gpu}'
