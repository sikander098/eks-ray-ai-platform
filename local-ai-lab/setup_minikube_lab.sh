#!/bin/bash
set -e

echo "🚀 Starting Local AI Lab Setup (Minikube + NVIDIA GPU)"

# 0. Clean up potential conflicts
echo "🧹 Cleaning up Kind and old Minikube profiles..."
kind delete cluster --name ai-platform || true
minikube delete -p ai-platform || true

# 1. Start Minikube with GPU passthrough
echo "🏗️  Starting Minikube 'ai-platform' with GPUs..."
# --gpus=all is the magic flag that Kind lacks
minikube start --driver=docker --container-runtime=docker --gpus=all -p ai-platform --addons=nvidia-device-plugin

# 2. Time-Slicing Configuration
# Minikube installs the device plugin automatically with --addons, but we need to patch it for Time-Slicing.
# Or better: We disable the default addon and install our own Helm chart to control the config.

echo "🎨 Configuring Time-Slicing (4 vGPUs)..."
# Disable default simpler plugin if it's running
minikube addons disable nvidia-device-plugin -p ai-platform || true

# Install Helm Chart with our ConfigMap
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

helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update

helm upgrade --install nvdp nvdp/nvidia-device-plugin \
  --namespace nvidia-device-plugin \
  --create-namespace \
  --version 0.14.3 \
  --set config.name=time-slicing-config

echo "⏳ Waiting for Device Plugin..."
kubectl rollout status ds/nvdp-nvidia-device-plugin -n nvidia-device-plugin

echo "✅ Done. Verifying capacity..."
# Wait loop
for i in {1..10}; do
  CAPACITY=$(kubectl get node -o jsonpath='{.items[0].status.capacity.nvidia\.com/gpu}')
  if [[ "$CAPACITY" == "4" ]]; then
    echo "🎉 SUCCESS: Node is advertising 4 Virtual GPUs!"
    break
  fi
  echo "Waiting for node capacity update... (attempt $i/10)"
  sleep 5
done

echo "🚀 Setup Complete! Run 'kubectl apply -f gpu-test-pod.yaml' to test."
