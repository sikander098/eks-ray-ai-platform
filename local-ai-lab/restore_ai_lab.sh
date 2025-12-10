#!/bin/bash
set -e
echo "🚀 Restoring AI Lab (Minikube + NVIDIA GPU + Time-Slicing)"

# 1. Start Minikube
if ! minikube status | grep -q "Running"; then
    echo "🏗️  Starting Minikube..."
    minikube start --driver=docker --container-runtime=docker --gpus=all -p ai-platform --addons=nvidia-device-plugin
else
    echo "✅ Minikube is already running."
fi

# 2. Apply Time-Slicing Patch
echo "🎨 Applying Time-Slicing Patch..."
chmod +x setup_timeslicing_patch.sh
./setup_timeslicing_patch.sh

echo "🎉 AI Lab is Ready!"
echo "Validating..."
kubectl get node -o jsonpath='{.items[0].status.capacity.nvidia\.com/gpu}'
echo " vGPUs available."
