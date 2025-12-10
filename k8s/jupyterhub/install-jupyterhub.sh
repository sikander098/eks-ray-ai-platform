#!/bin/bash
# Install JupyterHub
set -e

echo "📦 Adding JupyterHub Helm repository..."
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

echo "⚙️  Installing JupyterHub..."
helm upgrade --install jupyterhub jupyterhub/jupyterhub \
  --namespace jupyterhub \
  --create-namespace \
  --version 3.2.1 \
  --values values.yaml \
  --wait
  
echo "✅ JupyterHub installed!"
echo "🌐 Get the LoadBalancer IP with: kubectl get svc -n jupyterhub proxy-public"
