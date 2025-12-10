#!/bin/bash
set -e
echo "🏗️  Resuming Setup: Installing NVIDIA Device Plugin (ConfigMap method)..."

# 1. Create the ConfigMap manually
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

# 2. Install Helm Chart referencing the ConfigMap
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update

helm upgrade --install nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia-device-plugin \
  --create-namespace \
  --version 0.14.3 \
  --set config.name=time-slicing-config

echo "✅ NVIDIA Device Plugin installed."
echo "⏳ Waiting for rollout..."
kubectl rollout status ds/nvdp-nvidia-device-plugin -n nvidia-device-plugin
echo "🚀 Done!"
