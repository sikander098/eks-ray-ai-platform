#!/bin/bash
# Install KubeRay Operator
set -e

echo "📦 Adding KubeRay Helm repository..."
helm repo add kuberay https://ray-project.github.io/kuberay-helm/
helm repo update

echo "⚙️  Installing KubeRay Operator..."
# Install both operator and CRDs
helm upgrade --install kuberay-operator kuberay/kuberay-operator \
  --namespace ray-system \
  --create-namespace \
  --version 1.0.0 \
  --wait

echo "✅ KubeRay Operator installed!"
